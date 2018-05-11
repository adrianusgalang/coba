queryUtil = require '../query_util'
moment = require 'moment'

class TransactionsByPaymentMethod
  query = "
    select
      t.payment_method,
      count(id) as count
    from
      deposit_topups t
    where t.amount<5e8 AND t.amount>0 AND
      t.created_at >= ?
      and t.created_at < ?
    group by
      t.payment_method"

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

module.exports = TransactionsByPaymentMethod
