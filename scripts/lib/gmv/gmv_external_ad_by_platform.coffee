queryUtil = require '../query_util'
moment = require 'moment'

class GmvByPlatform
  query = "
    select
      sum(amount) as gmv
    from
      external_ad_purchases
    where
      created_at >= ?
      and created_at < ?"

  constructor: (queryStart, queryEnd) ->
    @queryStart = moment(queryStart)
    @queryEnd = moment(queryEnd)

  load: (cb) ->
    queryUtil.batchQuery query, @queryStart, @queryEnd, (err, results) ->
      if err then return cb(err, null)
      reduceFunc = (total, rows) -> total + rows[0].gmv
      cb(null, {desktop_web: results.reduce(reduceFunc, 0)})

module.exports = GmvByPlatform
