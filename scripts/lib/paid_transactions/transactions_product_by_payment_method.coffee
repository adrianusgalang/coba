async = require 'async'
moment = require 'moment'
queryUtil = require '../query_util'

class TransactionsByPaymentMethod
  query = "
    select
      payment_method,
      count(*) as count
    from payment_transactions
    where
      paid_at >= ?
      and paid_at < ?
      and fake = 0
    group by
      payment_method"

  constructor: (queryStart, queryEnd) ->
    @queryStart = moment(queryStart)
    @queryEnd = moment(queryEnd)

  load: (cb) ->
    queryUtil.batchQuery query, @queryStart, @queryEnd, (err, results) =>
      if err then return cb(err, null)
      countByPaymentMethod = {}
      results.forEach (rows) ->
        rows.forEach (row) ->
          currentTotal = countByPaymentMethod[row.payment_method] or 0
          countByPaymentMethod[row.payment_method] = currentTotal + row.count
      cb(null, countByPaymentMethod)

module.exports = TransactionsByPaymentMethod
