queryUtil = require '../query_util'
moment = require 'moment'

class TransactionsElectricity
  query = "
    select
      count(id) as count
    from
      payment_electricity_transactions
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
      cb(null, results.reduce(reduceFunc, 0))

module.exports = TransactionsElectricity
