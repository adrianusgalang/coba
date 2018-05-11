async = require 'async'
moment = require 'moment'
queryUtil = require '../query_util'

class TransactionsByProductType
  query = "
    select
      CASE
         WHEN t.seller_id = 13916224 THEN 'premium_subscription'
         WHEN t.seller_id = 34102071 THEN 'data_plan'
         WHEN t.seller_id = 17231263 THEN 'phone_credit'
         ELSE 'marketplace'
       END AS product_type,
      count(*) as count
    from
      payment_transactions t
    where  t.amount<5e8 AND
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
      countByProductType = {}
      results.forEach (rows) ->
        rows.forEach (row) ->
          currentTotal = countByProductType[row.product_type] or 0
          countByProductType[row.product_type] = currentTotal + row.count
      cb(null, countByProductType)

module.exports = TransactionsByProductType
