queryUtil = require '../query_util'
moment = require 'moment'

class Transactions
  query = (queryStart, queryEnd) -> "
    select
      count(t.id) as count
    from
      bukareksa_transactions t
      inner join payment_invoiceable_mappers m
        on t.id = m.invoiceable_id
        and m.invoiceable_type = 'Bukareksa::Transaction'
      inner join payment_invoices i
        on m.invoice_id = i.id
    where
      t.transaction_type = 'subscription'
      and t.created_at >= '#{queryStart.format('YYYY-MM-DD HH:mm:ss')}'-interval 2 day-interval 7 hour
      and t.created_at < '#{queryEnd.format('YYYY-MM-DD HH:mm:ss')}'+interval 17 hour
      and i.paid_at >= ?
      and i.paid_at < ?"

  constructor: (queryStart, queryEnd) ->
    @queryStart = moment(queryStart)
    @queryEnd = moment(queryEnd)

  load: (cb) ->
    queryUtil.batchQuery query(@queryStart, @queryEnd), @queryStart, @queryEnd, (err, results) ->
      if err then return cb(err, null)
      reduceFunc = (total, rows) -> total + rows[0].count
      cb(null, results.reduce(reduceFunc, 0))

module.exports = Transactions
