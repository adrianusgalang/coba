queryUtil = require '../query_util'
moment = require 'moment'

class GmvByPaymentMethod
  query = (queryStart, queryEnd) -> "
    select
      i.payment_method as payment_method,
      sum(t.total_amount + COALESCE(i.uniq_code,COALESCE(i.service_fee,0))) as gmv
    from
      bukareksa_transactions t
      inner join payment_invoiceable_mappers m
        on t.id = m.invoiceable_id
        and m.invoiceable_type = 'Bukareksa::Transaction'
      inner join payment_invoices i
        on m.invoice_id = i.id
    where t.amount<5e8 AND
      t.transaction_type='subscription' 
      and t.created_at >= '#{queryStart.format('YYYY-MM-DD HH:mm:ss')}'-interval 2 day-interval 7 hour
      and t.created_at < '#{queryEnd.format('YYYY-MM-DD HH:mm:ss')}'+interval 17 hour
    group by
      payment_method"

  constructor: (queryStart, queryEnd) ->
    @queryStart = moment(queryStart)
    @queryEnd = moment(queryEnd)

  load: (cb) ->
    queryUtil.batchQuery query(@queryStart, @queryEnd), @queryStart, @queryEnd, (err, results) ->
      if err then return cb(err, null)
      gmvByPaymentMethod = {}
      results.forEach (rows) ->
        rows.forEach (row) ->
          currentTotal = gmvByPaymentMethod[row.payment_method] or 0
          gmvByPaymentMethod[row.payment_method] = currentTotal + row.gmv
      cb(null, gmvByPaymentMethod)

module.exports = GmvByPaymentMethod
