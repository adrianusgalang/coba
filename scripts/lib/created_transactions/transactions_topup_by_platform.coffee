queryUtil = require '../query_util'
async = require 'async'
moment = require 'moment'

class TransactionsByPlatform
  query = "
    select
      case 
        when
          d.user_type = 'User' and d.user_id in #{queryUtil.caeID} then 'cae' 
        when
          a.user_id is not null then 'o2o'
        when 
          t.created_on LIKE '2%' OR t.created_on IS NULL THEN 'desktop_web'
        else
          t.created_on
        end as platform,
      count(t.id) as count
    from
      deposit_topups t
      inner JOIN deposit_deposits d ON t.deposit_id = d.id
      left join virtual_product_agents a
        on d.user_id = a.user_id
        and a.deleted = false
        and a.status = 1
    where t.amount<5e8 AND t.amount>0
      and t.created_at >= ?
      and t.created_at < ?
    group by
      platform"

  constructor: (queryStart, queryEnd) ->
    @queryStart = moment(queryStart)
    @queryEnd = moment(queryEnd)

  load: (cb) ->
    queryUtil.batchQuery query, @queryStart, @queryEnd, (err, results) ->
      if err then return cb(err, null)
      countByPlatform = {}
      results.forEach (rows) ->
        rows.forEach (row) ->
          currentTotal = countByPlatform[row.platform] or 0
          countByPlatform[row.platform] = currentTotal + row.count
      cb(null, countByPlatform)

module.exports = TransactionsByPlatform
