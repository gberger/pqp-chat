express = require('express')
app = express()
server = require('http').createServer(app)
io = require('socket.io').listen(server)

cors = require('cors')

###
	MIDDLEWARE
###

app.use cors()
app.use express.static(__dirname + '/public')

###
	SERVER START
###
server.listen(process.env.PORT || 5000)

###
	SOCKET.IO
###
io.set 'origins', '*:*'
io.sockets.on 'connection', (socket) ->
	socket.on 'send-message', (data) ->
		console.log 'Message received: ', data
		socket.emit 'broadcast-message', data
		socket.broadcast.emit 'broadcast-message', data
