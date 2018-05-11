queryUtil = require '../query_util'
async = require 'async'
moment = require 'moment'

class RevenueByPlatform
  query = "
    select
      platform,
      sum(CASE WHEN revenue_type regexp 'refunded|reverted' THEN -amount ELSE amount END) AS revenue
    from revenue_logs
    where
      fake=0 and created_at >= ?
      and created_at < ?
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
          current_revenue = data[row.platform] or 0
          data[row.platform] = current_revenue + Number(row.revenue)
      cb(null, data)

module.exports = RevenueByPlatform
