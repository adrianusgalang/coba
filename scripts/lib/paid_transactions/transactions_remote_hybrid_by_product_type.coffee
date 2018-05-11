queryUtil = require '../query_util'
moment = require 'moment'

class TransactionsByProductType
  query = "
    select
      remote_type as product_type,
      count(*) as count
    from
      remote_hybrid_transactions
    where
      remote_type!='bullion-withdrawal' AND paid_at >= ?
      and paid_at < ?
    group by
      product_type"

  constructor: (queryStart, queryEnd) ->
    @queryStart = moment(queryStart)
    @queryEnd = moment(queryEnd)

  load: (cb) ->
    queryUtil.batchQuery query, @queryStart, @queryEnd, (err, results) ->
      if err then return cb(err, null)
      countByProductType = {}
      results.forEach (rows) ->
        rows.forEach (row) ->
          currentTotal = countByProductType[row.product_type] or 0
          countByProductType[row.product_type] = currentTotal + row.count
      cb(null, countByProductType)

module.exports = TransactionsByProductType
