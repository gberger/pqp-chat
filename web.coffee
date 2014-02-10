express = require('express')
app = express()
server = require('http').createServer(app)
io = require('socket.io').listen(server)

cors = require('cors')

###
	MIDDLEWARE
###

app.use cors()

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
		io.sockets.emit "broadcast-message-#{data.course_abbreviation}", data
