_ = require('underscore')
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
io.set 'origins', '*:*'

mongo.Db.connect mongoUri, (err, db) ->
	throw err if err
	dbUsers = db.collection('users')
	dbMessages = db.collection('messages')

	emitMessage = (data) ->
		filteredData = _.pick(data, 'name', 'msg', 'course', 'timestamp')
		io.sockets.emit "broadcast-message-#{data.course}", filteredData

	saveMessage = (data) ->
		filteredData = _.pick(data, 'name', 'msg', 'course', 'timestamp')
		dbMessages.insert filteredData, (err, data) ->
			throw err if err

	io.sockets.on 'connection', (socket) ->

		socket.on 'request-recent', (data) ->
			dbMessages.find(course: data.course).sort(timestamp: -1).limit(20).toArray (err, results) ->
				throw err if err
				for message in results by -1
					emitMessage(message)

		socket.on 'send-message', (data) ->

			data.timestamp = +new Date()

			dbUsers.find({oauth_token: data.oauth_token}).toArray (err, results) ->
				throw err if err
				user = results[0]

				if user
					data.name = user['name']
					emitMessage data
					saveMessage data
				else
					request.get json: true, uri: "https://graph.facebook.com/me?fields=name&access_token=#{data.oauth_token}",
						(err, resp, body) ->
							throw err if err
							data.name = body.name
							dbUsers.insert {name: data.name, oauth_token: data.oauth_token}, (err, data) ->
								throw err if err
							emitMessage data
							saveMessage data