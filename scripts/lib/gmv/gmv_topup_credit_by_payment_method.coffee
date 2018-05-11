queryUtil = require '../query_util'
moment = require 'moment'

class GmvByPaymentMethod
  query = "
    select
      i.payment_method as payment_method,
      sum(t.amount + COALESCE(i.uniq_code,COALESCE(i.service_fee,0))) as gmv
    from
      deposit_rewards_topups t
      inner join payment_invoiceable_mappers m
        on t.id = m.invoiceable_id
        and m.invoiceable_type = 'Deposit::Rewards::Topup'
      inner join payment_invoices i
        on m.invoice_id = i.id
    where t.amount>0 AND
      t.processed_at >= ?
      and t.processed_at < ?
    group by
      payment_method"

  constructor: (queryStart, queryEnd) ->
    @queryStart = moment(queryStart)
    @queryEnd = moment(queryEnd)

  load: (cb) ->
    queryUtil.batchQuery query, @queryStart, @queryEnd, (err, results) ->
      if err then return cb(err, null)
      gmvByPaymentMethod = {}
      results.forEach (rows) ->
        rows.forEach (row) ->
          currentTotal = gmvByPaymentMethod[row.payment_method] or 0
          gmvByPaymentMethod[row.payment_method] = currentTotal + row.gmv
      cb(null, gmvByPaymentMethod)

module.exports = GmvByPaymentMethod
