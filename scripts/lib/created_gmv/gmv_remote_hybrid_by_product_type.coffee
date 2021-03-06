queryUtil = require '../query_util'
moment = require 'moment'

class GmvByProductType
  query = "
    select
      remote_type as product_type,
      sum(t.amount + COALESCE(i.uniq_code,COALESCE(i.service_fee,0))) as gmv
    from
      remote_hybrid_transactions t
      inner join payment_invoiceable_mappers m
        on t.id = m.invoiceable_id
        and m.invoiceable_type = 'Remote::HybridTransaction'
      inner join payment_invoices i
        on m.invoice_id = i.id
    where
      t.remote_type!='bullion-withdrawal'
      and  t.amount<5e8 AND
      t.created_at >= ?
      and t.created_at < ?
    group by
      product_type"

  constructor: (queryStart, queryEnd) ->
    @queryStart = moment(queryStart)
    @queryEnd = moment(queryEnd)

  load: (cb) ->
    queryUtil.batchQuery query, @queryStart, @queryEnd, (err, results) ->
      if err then return cb(err, null)
      gmvByProductType = {}
      results.forEach (rows) ->
        rows.forEach (row) ->
          currentTotal = gmvByProductType[row.product_type] or 0
          gmvByProductType[row.product_type] = currentTotal + row.gmv
      cb(null, gmvByProductType)

module.exports = GmvByProductType
