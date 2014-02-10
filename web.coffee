express = require('express')
app = express()
server = require('http').createServer(app)
io = require('socket.io').listen(server)

cors = require('cors')

###
	MIDDLEWARE
###

# CORS
whitelist = [
	'http://pucquepariu.com.br'
	'https://pucquepariu.com.br'
	'http://www.pucquepariu.com.br'
	'https://www.pucquepariu.com.br'
	'http://pucquepariu.herokuapp.com'
	'https://pucquepariu.herokuapp.com'
	'http://pucquepariu2.herokuapp.com'
	'https://pucquepariu2.herokuapp.com'
]
app.use cors({
	origin: (origin, callback) ->
		callback null, origin in whitelist
})

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
