queryUtil = require '../query_util'
moment = require 'moment'

class TransactionsByPaymentMethod
  query = "
    select
      i.payment_method as payment_method,
      count(*) as count
    from
      remote_transactions t
      inner join payment_invoiceable_mappers m
        on t.id = m.invoiceable_id
        and m.invoiceable_type = 'Remote::Transaction'
      inner join payment_invoices i
        on m.invoice_id = i.id
    where
      t.remote_type not in ['bullion-redeem', 'electricity-prepaid'] AND
      t.amount<5e8 AND
      t.created_at >= ?
      and t.created_at < ?
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

module.exports = TransactionsByPaymentMethod
