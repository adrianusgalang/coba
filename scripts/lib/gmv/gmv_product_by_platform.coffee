async = require 'async'
moment = require 'moment'
queryUtil = require '../query_util'

class GmvByPlatform
  query = "
    select
      case 
        when
          t.buyer_type = 'User' and t.buyer_id in #{queryUtil.caeID} then 'cae' 
        when
          a.user_id is not null then 'o2o'
        when 
          t.created_on LIKE '2%' OR t.created_on IS NULL THEN 'desktop_web'
        else
          t.created_on
        end as platform,
      sum(t.amount + coalesce(t.courier_cost, 0) + coalesce(t.uniq_code, coalesce(t.service_fee, 0)) + t.agent_commission_amount + t.insurance_cost) as gmv
    from
      payment_transactions t
      left join virtual_product_agents a
        on t.buyer_id = a.user_id
        and a.deleted = false
        and a.status = 1
    where
      t.paid_at >= ?
      and t.paid_at < ?
      and t.fake = 0
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
