require('dotenv').config()

dataChannel = process.env.SLACK_DATA_CHANNEL_ID

module.exports.dataChannelId = dataChannel

# msg: hubot Response instance
module.exports.authorized = (msg) ->
  return msg.message.room is dataChannel
