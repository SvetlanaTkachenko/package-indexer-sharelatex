logger = require "logger-sharelatex"
Errors = require "./Errors"
fs = require "fs"
{db, ObjectId} = require "./mongojs"

module.exports = HttpController =

	something: (req, res) ->
		logger.log "Something works"
		res.send 200

	packageIndex: (req, res, next = (error) ->) ->
		HttpController.load_index (err, index_data) ->
			return next(err) if err?
			res.setHeader "Content-Type", "application/json"
			res.status(200).send(index_data)

	search: (req, res, next = (error) ->) ->
		search_params = req.body
		# simple regex match on the name field for now.
		query =
			name: {$regex: new RegExp("^#{search_params.query}", 'i')}
			language: search_params.language or 'python'
		logger.log params: search_params, "searching package index"
		db.packageIndex.find(query).limit 100, (err, docs=[]) ->
			if err
				return next err
			logger.log params: search_params, count: docs.length, "found packages in index, sending to client"
			res.setHeader "Content-Type", "application/json"
			result =
				searchParams: search_params
				results: docs
			res.status(200).send(result)

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
