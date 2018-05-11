queryUtil = require '../query_util'
async = require 'async'
moment = require 'moment'

class Revenue
  query = "
    select
      sum(CASE WHEN revenue_type regexp 'refunded|reverted' THEN -amount ELSE amount END) AS revenue
    from revenue_logs
    where
      fake=0 and created_at >= ?
      and created_at < ?"

  constructor: (queryStart, queryEnd) ->
    @queryStart = moment(queryStart)
    @queryEnd = moment(queryEnd)
    #console.log("masuk revenue")

  load: (cb) ->
    queryUtil.batchQuery query, @queryStart, @queryEnd, (err, results) ->
      if err then return cb(err, null)
      reduceFunc = (total, rows) -> total + Number(rows[0].revenue)
      cb(null, results.reduce(reduceFunc, 0))

module.exports = Revenue
