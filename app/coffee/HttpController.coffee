logger = require "logger-sharelatex"
Errors = require "./Errors"
fs = require "fs"

module.exports = HttpController =

	something: (req, res) ->
		logger.log "Something works"
		res.send 200

	packageIndex: (req, res, next = (error) ->) ->
		HttpController.load_index (err, index_data) ->
			return next(err) if err?
			res.setHeader "Content-Type", "application/json"
			res.status(200).send(index_data)

	load_index: (callback) ->
		index_path = __dirname + '/../../data/packageIndex.json'
		fs.readFile index_path, (err, data) ->
			if err?
				logger.log path: index_path, "error reading index file"
				return callback(err, null)
			json_data = null
			try
				json_data = JSON.parse data
			catch err
				logger.log path: index_path, "error parsing index file"
				return callback(err, null)
			return callback(null, json_data)
