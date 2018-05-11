# Description:
#   Provides endpoint for health checking.

module.exports = (robot) ->
  robot.router.get '/healthz', (req, res) ->
    if robot.adapter.client.rtm.connected
      res.send('OK')
    else
      res.status(503).send('ERR')
