queryUtil = require '../query_util'
moment = require 'moment'

class Transactions
  query = "
    select
      count(t.id) as count
    from
      deposit_rewards_topups t
    where t.amount<5e8 AND t.amount>0 AND
      t.created_at >= ?
      and t.created_at < ?"

  constructor: (queryStart, queryEnd) ->
    @queryStart = moment(queryStart)
    @queryEnd = moment(queryEnd)

  load: (cb) ->
    queryUtil.batchQuery query, @queryStart, @queryEnd, (err, results) ->
      if err then return cb(err, null)
      reduceFunc = (total, rows) -> total + rows[0].count
      cb(null, results.reduce(reduceFunc, 0))

module.exports = Transactions
