cli = require 'cli'
fs = require 'fs'
child_process = require 'child_process'
logger = require 'logger-sharelatex'
_ = require 'underscore'
async = require 'async'
{db, ObjectId} = require './app/js/mongojs'

pypi_url = 'http://pypi.local'


module.exports = Indexer =

	save_index_to_mongo: (index, callback) ->
		db.packageIndex.ensureIndex {language: 1, name: 1}, {}, (err, result) ->
			if err
				return callback err
			packages = []
			for name in Object.keys(index.packages.python)
				p = index.packages.python[name]
				p.language = 'python'
				packages.push(p)
			for name in Object.keys(index.packages.r)
				p = index.packages.r[name]
				p.language = 'r'
				packages.push(p)
			logger.log count: packages.length, "writing index to mongo"
			async.mapLimit(packages, 100,
				(doc, cb) ->
					db.packageIndex.update {language: doc.language, name: doc.name}, doc, {upsert: true}, (err, result) ->
						cb err, null
				(err, results) ->
					if err
						return callback err, null
					callback null
			)

cli.parse(
	inputfile: ['i', 'input file name', 'string', 'data/packageIndex.json']
)

cli.main (args, options) ->
	input_file = options.inputfile
	data = fs.readFileSync input_file
	index = JSON.parse data

	Indexer.save_index_to_mongo index, (err) ->
		if err?
			throw err
		logger.log "done"
		process.exit()
