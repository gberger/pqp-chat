express = require('express')
app = express()
server = require('http').createServer(app)
io = require('socket.io').listen(server)

###
	MIDDLEWARE
###

# CORS
app.use (err, req, res, next) ->
	allowedDomains = [
		'http://pucquepariu.com.br'
		'https://pucquepariu.com.br'
		'http://www.pucquepariu.com.br'
		'https://www.pucquepariu.com.br'
		'http://pucquepariu.herokuapp.com'
		'https://pucquepariu.herokuapp.com'
		'http://pucquepariu2.herokuapp.com'
		'https://pucquepariu2.herokuapp.com'
	]

	if req.headers.origin in allowedDomains
		res.header('Access-Control-Allow-Origin', req.headers.origin);
		res.header('Access-Control-Allow-Methods', 'GET,PUT,POST,DELETE');
		res.header('Access-Control-Allow-Headers', 'Content-Type');

	next()

# Serve static content
app.use express.static(__dirname + '/public')

###
	SERVER START
###
server.listen(process.env.PORT || 5000)

###
	SOCKET.IO
###
io.sockets.on 'connection', (socket) ->
	socket.on 'send-message', (data) ->
		console.log 'Message received: ', data
		socket.emit 'broadcast-message', data
		socket.broadcast.emit 'broadcast-message', data
