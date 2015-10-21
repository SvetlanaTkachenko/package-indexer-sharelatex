logger = require "logger-sharelatex"
Errors = require "./Errors"
fs = require "fs"
HealthChecker = require "./HealthChecker"
{db, ObjectId} = require "./mongojs"

module.exports = HttpController =

	something: (req, res) ->
		logger.log "Something works"
		res.send 200

	health_check: (req, res) ->
		logger.log "performing health check"
		HealthChecker.check (err) ->
			if err?
				logger.log err: err, "error performing health check"
				res.send 500
			else
				res.send 200

	search: (req, res, next = (error) ->) ->
		search_params = req.body
		if !search_params? or !search_params.language? or !search_params.query?
			return res.send 400
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
