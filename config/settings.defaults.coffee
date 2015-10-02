http = require('http')
http.globalAgent.maxSockets = 300

module.exports =
	internal:
		packageindexer:
			port: 3022
			host: "localhost"

	mongo:
		url: 'mongodb://127.0.0.1/sharelatex'
