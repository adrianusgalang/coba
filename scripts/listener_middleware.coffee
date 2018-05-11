# Description:
#   Hubot listener middleware.

auth = require('./lib/auth')

module.exports = (robot) ->

  # authorize message's channel.
  robot.listenerMiddleware (context, next, done) ->
    if auth.authorized(context.response)
      next()
    else
      done()

  # add reaction to acknowledge message with registered command.
  robot.listenerMiddleware (context, next, done) ->
    if robot.adapter.client && robot.adapter.client.constructor.name == 'SlackClient'
      robot.adapter.client.web.reactions.add 'ok_hand',
        channel: auth.dataChannelId
        timestamp: context.response.message.id
    next()
