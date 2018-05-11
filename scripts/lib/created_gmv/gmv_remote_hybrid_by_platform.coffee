queryUtil = require '../query_util'
async = require 'async'
moment = require 'moment'

class GmvByPlatform
  query = "
    select
      case 
        when
          i.buyer_type = 'User' and i.buyer_id in #{queryUtil.caeID} then 'cae' 
        when
          a.user_id is not null then 'o2o'
        when 
          i.created_on LIKE '2%' OR i.created_on IS NULL THEN 'desktop_web'
        else
          i.created_on
        end as platform,
      sum(t.amount + COALESCE(i.uniq_code,COALESCE(i.service_fee,0))) as gmv
    from
      remote_hybrid_transactions t
      inner join payment_invoiceable_mappers m
        on t.id = m.invoiceable_id
        and m.invoiceable_type = 'Remote::HybridTransaction'
      inner join payment_invoices i
        on m.invoice_id = i.id
      left join virtual_product_agents a
        on i.buyer_id = a.user_id
        and a.deleted = false
        and a.status = 1
    where
      t.remote_type!='bullion-withdrawal' 
      and  t.amount<5e8 AND
      t.created_at >= ?
      and t.created_at < ?
    group by
      platform"

  constructor: (queryStart, queryEnd) ->
    @queryStart = moment(queryStart)
    @queryEnd = moment(queryEnd)

  load: (cb) ->
    queryUtil.batchQuery query, @queryStart, @queryEnd, (err, results) ->
      if err then return cb(err, null)
      gmvByPlatform = {}
      results.forEach (rows) ->
        rows.forEach (row) ->
          currentTotal = gmvByPlatform[row.platform] or 0
          gmvByPlatform[row.platform] = currentTotal + row.gmv
      cb(null, gmvByPlatform)

module.exports = GmvByPlatform
