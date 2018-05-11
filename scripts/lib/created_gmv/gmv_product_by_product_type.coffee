async = require 'async'
moment = require 'moment'
queryUtil = require '../query_util'

class GmvByProductType
  query = "
    select
       CASE
         WHEN t.seller_id = 13916224 THEN 'premium_subscription'
         WHEN t.seller_id = 34102071 THEN 'data_plan'
         WHEN t.seller_id = 17231263 THEN 'phone_credit'
         ELSE 'marketplace'
       END AS product_type,  
      sum(t.amount + coalesce(t.courier_cost, 0) + coalesce(t.uniq_code, coalesce(t.service_fee, 0)) + t.agent_commission_amount + t.insurance_cost) as gmv
    from
      payment_transactions t
    where t.amount<5e8 AND
      t.created_at >= ?
      and t.created_at < ?
      and t.fake = 0
    group by
      product_type"

  constructor: (queryStart, queryEnd) ->
    @queryStart = moment(queryStart)
    @queryEnd = moment(queryEnd)

  load: (cb) ->
    queryUtil.batchQuery query, @queryStart, @queryEnd, (err, results) =>
      if err then return cb(err, null)
      gmvByProductType = {}
      results.forEach (rows) ->
        rows.forEach (row) ->
          currentTotal = gmvByProductType[row.product_type] or 0
          gmvByProductType[row.product_type] = currentTotal + row.gmv
      cb(null, gmvByProductType)

module.exports = GmvByProductType
