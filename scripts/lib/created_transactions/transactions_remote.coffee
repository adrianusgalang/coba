queryUtil = require '../query_util'
moment = require 'moment'

class Transactions
  query = "
    select
      count(*) as count
    from
      remote_transactions
    where
      remote_type not in ['bullion-redeem', 'electricity-prepaid'] AND
      amount<5e8 AND
      created_at >= ?
      and created_at < ?"

  constructor: (queryStart, queryEnd) ->
    @queryStart = moment(queryStart)
    @queryEnd = moment(queryEnd)

  load: (cb) ->
    queryUtil.batchQuery query, @queryStart, @queryEnd, (err, results) ->
      if err then return cb(err, null)
      reduceFunc = (total, rows) -> total + rows[0].count
      cb(null, results.reduce(reduceFunc, 0))

module.exports = Transactions
