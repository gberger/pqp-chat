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

	db.use modts,
		modifiedProperty: 'updated_at'

	User = db.define 'users',
		name: String
		oauth_token: String
		role: String

	Course = db.define 'courses',
		name: String
		abbreviation: String
		teacher_id: Number

	ChatMessage = db.define 'chat_messages',
		text: String
		course_id: Number
	,
		timestamp: true

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

					message = new ChatMessage
						course_id: course.id
						user_id: user.id
						text: data.msg
					message.save (err) ->
						if err
							console.error err.msg
							throw err

						data.id = message.id
						filteredData = _.pick(data, 'name', 'msg', 'course', 'timestamp', 'id')
						io.sockets.emit "broadcast-message-#{data.course}", filteredData
						console.info "ChatMessage: #{JSON.stringify(filteredData)}"

		socket.on 'delete-message', (data) ->
			ChatMessage.get data.id, (err, msg) ->
				throw err if err

				User.find {oauth_token: data.oauth_token}, (err, users) ->
					throw err if err
					user = users[0]

					Course.get msg.course_id, (err, course) ->
						throw err if err
						return unless user.id == course.teacher_id || user.role == 'admin'

						msg.remove (err) ->
							throw err if err
							io.sockets.emit "broadcast-delete-message", id: data.id
