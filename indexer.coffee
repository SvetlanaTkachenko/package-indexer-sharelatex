fs = require 'fs'
child_process = require 'child_process'
request = require 'request'
cheerio = require 'cheerio'
_ = require 'underscore'
async = require 'async'

module.exports = Indexer =

	_lines_to_packages: (lines) ->
		current = {
			name: null,
			descriptionLines: []
		}
		result = {}

		console.log ">> #{lines.length}"

		for line in lines
			console.log ">> #{line}"
			match = line.match(/^([\.|a-z|A-Z|0-9|-_]+)\s+- (.*)$/)  # package header line
			if match != null
				name = match[1]
				description = match[2]
				if current.name  # push current to result, reset current
					result[current.name]({name: current.name, description: current.descriptionLines.join('\n')})
					current.name = name
					current.descriptionLines = [description]
			else
				current.descriptionLines.push(line.trim())
		return result


	getCondaPackages: () ->
		result = {}
		conda_output = child_process.execSync ' conda search ".*" --names-only '
		names = conda_output.toString().split('\n').slice(1)  # skip first line of output
		(result[name] = {name: name, description: null, command: "conda install #{name}"} for name in names)
		return result

	getPipPackages: (callback) ->
		request.get {uri:'https://pypi.python.org/simple/'}, (err, response, body) ->
			if err?
				return callback err, null
			page = cheerio.load(body)
			package_names = page.root().text().split('\n').slice(1, 200)
			async.map(
				package_names,
				(package_name, cb) ->
					console.log ">> getting #{package_name}"
					opts =
						uri: "https://pypi.python.org/pypi/#{package_name}/json"
						json: true
					request.get opts, (err, response, body) ->
						if err?
							return cb err, null
						console.log ">> got #{package_name}"
						info =
							name: package_name,
							details: null
						if response.statusCode == 200
							info.details = body
						cb null, info
				(err, results) ->
					if err?
						return callback err, null
					packages = {}
					for p in results
						packages[p.name] = p.details
					callback null, packages
			)

	build: () ->
		index =
			indexBuiltAt: new Date().toISOString()
			packages:
				python: {}
				r: {}

		conda = Indexer.getCondaPackages()
		pip = Indexer.getPipPackages()

		console.log "    "
		console.log ">> conda: #{Object.keys(conda).length}"
		console.log conda[Object.keys(conda)[0]]
		console.log ">> pip: #{Object.keys(pip).length}"
		console.log pip[Object.keys(pip)[0]]




		return index


# args = process.argv.slice(2)
# result = Indexer.build()
# if '--save' in args
# 	result_json = JSON.stringify(result, null, 2)
# 	fs.writeFileSync(__dirname + '/data/packageIndex.json', result_json)
# console.log result
