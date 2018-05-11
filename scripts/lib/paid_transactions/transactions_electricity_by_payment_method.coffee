queryUtil = require '../query_util'
moment = require 'moment'

class TransactionsElectricityByPaymentMethod
  query = "
    select
      payment_method,
      count(id) as count
    from
      payment_electricity_transactions
    where
      paid_at >= ?
      and paid_at < ?
    group by
      payment_method"

  constructor: (queryStart, queryEnd) ->
    @queryStart = moment(queryStart)
    @queryEnd = moment(queryEnd)

  load: (cb) ->
    queryUtil.batchQuery query, @queryStart, @queryEnd, (err, results) ->
      if err then return cb(err, null)
      data = {}
      results.forEach (rows) ->
        rows.forEach (row) ->
          currentTotal = data[row.payment_method] or 0
          data[row.payment_method] = currentTotal + row.count
      cb(null, data)

module.exports = TransactionsElectricityByPaymentMethod
