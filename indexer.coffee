
Indexer =

	build: () ->
		index =
			indexBuiltAt: new Date().toISOString()
			packages:
				pyhon: {}
				r: {}

		return index


args = process.argv.slice(2)
result = Indexer.build()
if '--save' in args
	result_json = JSON.stringify(result, null, 2)
	fs.writeFileSync(__dirname + '/data/packageIndex.json', result_json)
console.log result
