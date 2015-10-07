Settings   = require "settings-sharelatex"
logger     = require "logger-sharelatex"
express    = require "express"
bodyParser = require "body-parser"
Errors     = require "./app/js/Errors"
Metrics    = require "metrics-sharelatex"
Path       = require "path"
HttpController = require "./app/js/HttpController"


app_name = "package-indexer"


Metrics.initialize(app_name)
logger.initialize(app_name)
Metrics.mongodb.monitor(Path.resolve(__dirname + "/node_modules/mongojs/node_modules/mongodb"), logger)
Metrics.event_loop?.monitor(logger)


app = express()


app.use Metrics.http.monitor(logger)
app.use bodyParser.json()


# Do routing here, example:
app.get '/something', HttpController.something
app.get '/index', HttpController.packageIndex
app.post '/search', HttpController.search


# Status Endpoint
app.get '/status', (req, res)->
	res.send("#{app_name} is alive")


# Error handler
app.use (error, req, res, next) ->
	logger.error err: error, "request errored"
	if error instanceof Errors.NotFoundError
		res.send 404
	else
		res.send(500, "Oops, something went wrong")


port = Settings.internal.packageindexer.port
host = Settings.internal.packageindexer.host
app.listen port, host, (error) ->
	throw error if error?
	logger.info "#{app_name} starting up, listening on #{host}:#{port}"
