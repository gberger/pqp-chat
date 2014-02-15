_ = require('underscore')
express = require('express')
app = express()
server = require('http').createServer(app)
io = require('socket.io').listen(server)
cors = require('cors')

app.use cors()
io.set 'origins', '*:*'

ORM = require('orm')
modts = require('orm-timestamps');
ORM.connect process.env.DATABASE_URL, (err, db) ->
	throw err if err

	db.use modts

	User = db.define 'users',
		name: String
		oauth_token: String
		is_admin: Boolean

	Course = db.define 'courses',
		name: String
		abbreviation: String

	ChatMessage = db.define 'chat_messages',
		created_at: Date
		updated_at: Date

	ChatMessage.hasOne('course', Course)
	ChatMessage.hasOne('user', User)


	server.listen(process.env.PORT || 5000)


	io.sockets.on 'connection', (socket) ->
		socket.on 'send-message', (data) ->
			data.timestamp = +new Date()
			User.find {oauth_token: data.oauth_token}, (err, users) ->
				throw err if err
				Course.find {abbreviation: data.course}, (err, courses) ->
					throw err if err

					user = users[0]
					course = courses[0]

					data.name = user.name
					data.msg = data.msg.slice(0, 512)
					filteredData = _.pick(data, 'name', 'msg', 'course', 'timestamp')
					io.sockets.emit "broadcast-message-#{data.course}", filteredData
					console.info "ChatMessage: #{JSON.stringify(filteredData)}"
					ChatMessage.create [{
						course_id: course
						user_id: user
						text: data.msg
					}], (err, items) ->
						throw err if err
