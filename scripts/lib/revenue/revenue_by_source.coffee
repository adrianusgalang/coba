queryUtil = require '../query_util'
async = require 'async'
moment = require 'moment'

class RevenueBySource
  query = "
    select
          CASE
              WHEN revenue_type IN ('push_package',
                                    'single_push') THEN 'push'
              WHEN revenue_type IN ('sem_budget',
                                    'daily_sem_budget_topup',
                                    'refunded_sem_budget') THEN 'promoted push'
              WHEN revenue_type IN ('premium_payment',
                                    'premium_auto_extend',
                                    'refunded_premium_payment') THEN 'premium'
              WHEN revenue_type IN ('unique_code',
                                    'revived_unique_code',
                                    'refunded_unique_code',
                                    'reverted_unique_code') THEN 'unique code'
              WHEN revenue_type IN ('push_package',
                                    'single_push') THEN 'push'
              ELSE revenue_type
          END AS revenue_type,
          sum(CASE WHEN revenue_type regexp 'refunded|reverted' THEN -amount ELSE amount END) AS revenue
    from revenue_logs
    where
      fake=0 and created_at >= ?
      and created_at < ?
    group by
      1"

  constructor: (queryStart, queryEnd) ->
    @queryStart = moment(queryStart)
    @queryEnd = moment(queryEnd)

  load: (cb) ->
    queryUtil.batchQuery query, @queryStart, @queryEnd, (err, results) ->
      if err then return cb(err, null)
      data = {}
      results.forEach (rows) ->
        rows.forEach (row) ->
          current_revenue = data[row.revenue_type] or 0
          data[row.revenue_type] = current_revenue + Number(row.revenue)
      cb(null, data)

module.exports = RevenueBySource
