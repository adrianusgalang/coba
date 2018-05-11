# Description:
#   Provides endpoint for metrics (nothing atm).

module.exports = (robot) ->
  robot.router.get '/metrics', (req, res) ->
    res.send('')
