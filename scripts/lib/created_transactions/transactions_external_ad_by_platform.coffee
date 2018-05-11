queryUtil = require '../query_util'
moment = require 'moment'

class TransactionsByPlatform
  query = "
    select
      count(*) as count
    from
      external_ad_purchases
    where amount<5e8 AND
      created_at >= ?
      and created_at < ?"

  constructor: (queryStart, queryEnd) ->
    @queryStart = moment(queryStart)
    @queryEnd = moment(queryEnd)

  load: (cb) ->
    queryUtil.batchQuery query, @queryStart, @queryEnd, (err, results) ->
      if err then return cb(err, null)
      reduceFunc = (total, rows) -> total + rows[0].count
      cb(null, {desktop_web: results.reduce(reduceFunc, 0)})

module.exports = TransactionsByPlatform
