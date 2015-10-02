logger = require "logger-sharelatex"
Errors = require "./Errors"

module.exports = HttpController =

	something: (req, res) ->
		logger.log "Something works"
		res.send 200
