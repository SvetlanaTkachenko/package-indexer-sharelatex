fs = require 'fs'
child_process = require 'child_process'
request = require 'request'
cheerio = require 'cheerio'
_ = require 'underscore'
async = require 'async'

module.exports = Indexer =

	getCondaPackages: () ->
		result = {}
		conda_output = child_process.execSync ' conda search ".*" --names-only '
		names = conda_output.toString().split('\n').slice(1)  # skip first line of output
		(result[name] = {name: name, description: null, url: null, summary: null,command: "conda install -y #{name}"} for name in names)
		return result

	getPipPackages: (callback) ->
		request.get {uri:'https://pypi.python.org/simple/'}, (err, response, body) ->
			if err?
				return callback err, null
			page = cheerio.load(body)
			package_names = page.root().text().split('\n').slice(1, 10000)  # FIXME: testing on just 200 packages
			async.map(
				package_names,
				(package_name, cb) ->
					# console.log ">> getting #{package_name}"
					opts =
						uri: "https://pypi.python.org/pypi/#{package_name}/json"
						json: true
						timeout: 600 * 1000
					request.get opts, (err, response, body) ->
						if err?
							error = new Error("Error: could not get #{package_name} from pypi. status: #{response?.statusCode}, message: #{err.message}")
							error.err = err
							return cb error, null
						info =
							name: package_name,
							details: if response.statusCode == 200 then body else null
						# console.log ">> got #{package_name}"
						cb null, info
				(err, results) ->
					if err?
						return callback err, null
					packages = {}
					for p in results
						packages[p.name] =
							name: p.name.toLowerCase()  # Because pip is case-insensitive, coerce to lowercase
							description: p?.details?.info.description
							url: p?.details?.info.package_url
							summary: p?.details?.info.summary
							command: "pip install '#{p.name}'"
					callback null, packages
			)

	buildPythonIndex: (callback) ->
		index =
			indexBuiltAt: new Date().toISOString()
			packages:
				python: {}
				r: {}

		conda_packages = Indexer.getCondaPackages()
		conda_names = _.keys(conda_packages)
		console.log ">> got all conda packages"

		Indexer.getPipPackages (err, pip_packages) ->
			if err?
				return callback err
			console.log ">> got all pip packages"
			pip_names = _.keys(pip_packages)
			pip_and_conda = _.intersection(conda_names, pip_names)
			conda_only = _.difference(conda_names, pip_names)
			pip_only = _.difference(pip_names, conda_names)

			# console.log conda_only
			console.log ">> pip: #{pip_only.length}"
			console.log ">> conda: #{conda_only.length}"
			console.log ">> both: #{pip_and_conda.length} : #{pip_and_conda}"

			python_packages = {}
			for name in conda_only
				python_packages[name] = conda_packages[name]

			for name in pip_and_conda
				p = Object.assign(pip_packages[name])
				p.command = conda_packages[name].command
				python_packages[name] = p

			for name in pip_only
				python_packages[name] = pip_packages[name]

			callback(null, python_packages)

	build: (callback) ->
		Indexer.buildPythonIndex (err, python_index) ->
			if err?
				return callback err
			final_index =
				indexBuiltAt: new Date().toISOString()
				packages:
					python: python_index
					r: {}
			callback null, final_index

args = process.argv.slice(2)
Indexer.build (err, result) ->
	if err
		throw err
	if '--save' in args
		result_json = JSON.stringify(result, null, 2)
		fs.writeFileSync(__dirname + '/data/packageIndex.json', result_json)
	if '--print' in args
		console.log result
