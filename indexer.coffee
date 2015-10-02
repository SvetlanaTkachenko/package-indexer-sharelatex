fs = require 'fs'
child_process = require 'child_process'

module.exports = Indexer =

	getCondaPackages: () ->
		output = child_process.execSync ' conda search ".*" --names-only '
		names = output.toString().split('\n').slice(1)

	build: () ->
		index =
			indexBuiltAt: new Date().toISOString()
			packages:
				python: {}
				r: {}

		return index


args = process.argv.slice(2)
result = Indexer.build()
if '--save' in args
	result_json = JSON.stringify(result, null, 2)
	fs.writeFileSync(__dirname + '/data/packageIndex.json', result_json)
console.log result
