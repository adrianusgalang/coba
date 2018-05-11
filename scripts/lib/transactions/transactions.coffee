queryUtil = require '../query_util'
async = require 'async'
moment = require 'moment'

class Transactions
  query = "
    select
      count(*) as count
    from payment_transactions
    where
      created_at >= ?
      and created_at < ?"

  constructor: (queryStart, queryEnd) ->
    @queryStart = moment(queryStart)
    @queryEnd = moment(queryEnd)

  load: (cb) ->
    queryUtil.batchQuery query, @queryStart, @queryEnd, (err, results) ->
      if err then return cb(err, null)
      reduceFunc = (total, rows) -> total + Number(rows[0].count)
      cb(null, results.reduce(reduceFunc, 0))

module.exports = Transactions
