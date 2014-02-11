express = require('express')
app = express()
server = require('http').createServer(app)
io = require('socket.io').listen(server)

request = require('request')


###
	MONGODB
###
mongo = require('mongodb')
mongoUri = process.env.MONGOLAB_URI || process.env.MONGOHQ_URL || 'mongodb://localhost/mydb';


###
	MIDDLEWARE
###
cors = require('cors')
app.use cors()


###
	SERVER START
###
server.listen(process.env.PORT || 5000)


###
	SOCKET.IO
###
emitMessage = (data) ->
	io.sockets.emit "broadcast-message-#{data.course_abbreviation}", _.pick(data, 'name', 'msg')

mongo.Db.connect mongoUri, (err, db) ->
	throw err if err

	io.set 'origins', '*:*'
	io.sockets.on 'connection', (socket) ->
		socket.on 'send-message', (data) ->

				dbUsers = db.collection('users')
				dbUsers.find({oauth_token: data.oauth_token}).toArray (err, results) ->
					throw err if err
					user = results[0]

					if user
						data.name = user['name']
						emitMessage data
					else
						request.get json: true, uri: "https://graph.facebook.com/me?fields=name&access_token=#{data.oauth_token}",
							(err, resp, body) ->
								throw err if err
								data.name = body.name
								dbUsers.insert name: data.name, oauth_token: data.oauth_token
								emitMessage data
