queryUtil = require '../query_util'
async = require 'async'
moment = require 'moment'

class TransactionsByPlatform
  #query belum benar
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
      count(t.id) as count
    from
      payment_electricity_transactions t
      left join virtual_product_agents a
        on t.buyer_id = a.user_id
        and a.deleted = false
        and a.status = 1
    where
      t.paid_at >= ?
      and t.paid_at < ?
    group by
      platform"

  constructor: (queryStart, queryEnd) ->
    @queryStart = moment(queryStart)
    @queryEnd = moment(queryEnd)

  load: (cb) ->
    queryUtil.batchQuery query, @queryStart, @queryEnd, (err, results) ->
      if err then return cb(err, null)
      data = {}
      results.forEach (rows) ->
        rows.forEach (row) ->
          currentTotal = data[row.platform] or 0
          data[row.platform] = currentTotal + row.count
      cb(null, data)

module.exports = TransactionsByPlatform
