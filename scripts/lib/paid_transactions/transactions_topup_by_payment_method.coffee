queryUtil = require '../query_util'
moment = require 'moment'

class TransactionsByPaymentMethod
  query = "
    select
      t.payment_method,
      count(dm.id) as count
    from
      deposit_mutations dm
      inner JOIN deposit_topups t ON t.id=dm.topup_id
    where
      dm.action IN ('user_topup','topup') and dm.amount>0
      and dm.created_at >= ?
      and dm.created_at < ?
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
