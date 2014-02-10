fs = require('fs')
app = require('http').createServer (req, res) ->
	fs.readFile __dirname + '/public/index.html', (err, data) ->
		if err
			res.writeHead 500
			return res.end 'Error loading index.html'

		res.writeHead 200
		res.end data

app.listen(process.env.PORT || 5000)


io = require('socket.io').listen(app)
io.sockets.on 'connection', (socket) ->
	socket.on 'send-message', (data) ->
		console.log 'Message received: ', data
		socket.emit 'broadcast-message', data
