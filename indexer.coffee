fs = require 'fs'
child_process = require 'child_process'
request = require 'request'
cheerio = require 'cheerio'
_ = require 'underscore'
async = require 'async'
CsvParse = require 'csv-parse'


pypi_url = 'http://pypi.local'


module.exports = Indexer =

	getCondaPackages: () ->
		result = {}
		conda_output = child_process.execSync ' conda search ".*" --names-only '
		names = _.without(conda_output.toString().split('\n').slice(1), '')  # skip first line of output
		(result[name] = {
			name: name,
			description: null,
			source: 'conda',
			url: null,
			summary: null,command: ["conda", "install", "-y", name]} for name in names)
		return result

	getPipPackages: (callback) ->
		request.get {uri:"http://pypi.python.org/simple/"}, (err, response, body) ->
			if err?
				return callback err, null
			page = cheerio.load(body)
			package_names = page.root().text().split('\n').slice(1)
			async.mapLimit(
				package_names,
				200,
				(package_name, cb) ->
					# console.log ">> getting #{package_name}"
					opts =
						uri: "#{pypi_url}/pypi/#{package_name}/json"
						json: true
						timeout: 600 * 1000
					request.get opts, (err, response, body) ->
						if err?
							error = new Error("Error: could not get #{package_name} from pypi. status: #{response?.statusCode}, #{err.message}")
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
							source: 'pip'
							url: p?.details?.info.package_url
							summary: p?.details?.info.summary
							command: ["pip", "install", p.name]
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
			console.log ">> both: #{pip_and_conda.length}"

			python_packages = {}
			for name in conda_only
				python_packages[name] = conda_packages[name]

			for name in pip_and_conda
				p = Object.assign(pip_packages[name])
				p.command = conda_packages[name].command
				p.source = 'conda'
				python_packages[name] = p

			for name in pip_only
				python_packages[name] = pip_packages[name]

			callback(null, python_packages)

	getAptCranPackages: () ->
		child_process.execSync ' sudo apt-get update '
		apt_packages = child_process.execSync ' apt-cache search "r-cran-.*" | grep "^r-cran.*$"'
		lines = apt_packages.toString().split('\n')
		packages = lines.map (line) ->
			console.log line
			match = line.match /^(.*) - (.*)$/
			if match
				name = match[1]
				summary = match[2]
				return {
					name: name.slice(7)
					summary: summary
					description: null
					source: 'apt'
					url: null
					command: ["sudo", "apt-get", "install", name]
				}
		result = {}
		for p in _.without(packages, undefined)
			result[p.name] = p
		result

	getRemoteCranPackages: (callback) ->
		command_out = child_process.execSync """
				echo 'write.table(available.packages(fields=c("Description", "Title")), sep=",")' | R --no-save --slave
		"""
		csv_data = command_out.toString()
		CsvParse csv_data, {delimiter: ',', columns: true}, (err, parsed) ->
			console.log parsed[0]
			if err
				callback err, null
			packages = parsed.map (row) ->
				name: row.Package
				summary: row.Title
				description: row.Description
				source: 'cran'
				url: "https://cran.rstudio.com/web/packages/#{row.Package}/index.html"
				command: [
					"sudo", "Rscript", "-e", "install.packages('#{row.Package}');
					suppressMessages(suppressWarnings(if(!require('#{row.Package}')) {
						stop('Could not load package', call.=FALSE)
					}))"
				]
			result = {}
			for p in packages
				result[p.name] = p

			callback null, result

	getBioConductorPackages: (callback) ->
		command_out = child_process.execSync """
			echo 'source("http://bioconductor.org/biocLite.R"); cat(BiocInstaller::all_group())' | R --no-save --slave
		"""
		bioc_packages = command_out.toString().split(" ")
		result = {}
		for name in bioc_packages
			result[name] =
				name: name
				summary: null
				description: null
				source: 'bioconductor'
				url: "http://bioconductor.org/packages/release/bioc/html/#{name}.html"
				command: [
					"sudo", "Rscript", "-e",
					"if (!require(BiocInstaller,quietly=TRUE)) {
						source('http://bioconductor.org/biocLite.R')
					} else {
						library(BiocInstaller);
					};
					biocLite('#{name}') ;
					suppressMessages(suppressWarnings(if(!require('#{name}')) {
						stop('Could not load package', call.=FALSE)
					}))"
				]
		callback null, result



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

# args = process.argv.slice(2)
# Indexer.build (err, result) ->
# 	if err
# 		throw err
# 	if '--save' in args
# 		result_json = JSON.stringify(result, null, 2)
# 		fs.writeFileSync(__dirname + '/data/packageIndex.json', result_json)
# 	if '--print' in args
# 		console.log result
