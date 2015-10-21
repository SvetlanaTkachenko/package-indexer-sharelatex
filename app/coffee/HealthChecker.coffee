logger = require "logger-sharelatex"
Errors = require "./Errors"
request = require "request"
settings = require "settings-sharelatex"

module.exports = HealthChecker =

	check: (callback) ->
		port = settings.internal.packageindexer.port
		url = "http://localhost:#{port}/search"
		opts =
			method: 'post'
			json: true
			body:
				language: 'python'
				query: 'flask'
			uri: url
			timeout: 60 * 1000 * 5
		request opts, (err, response, body) ->
			if err
				return callback err
			if response.statusCode != 200
				return callback(new Error("recieved status '#{response.statusCode}' from search endpoint"))
			return callback null
