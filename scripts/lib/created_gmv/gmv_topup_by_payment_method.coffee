queryUtil = require '../query_util'
moment = require 'moment'

class GmvByPaymentMethod
  query = "
    select
      t.payment_method,
      sum(t.amount) as gmv
    from
      deposit_topups t
    where t.amount<5e8 AND t.amount>0 AND
      t.created_at >= ?
      and t.created_at < ?
    group by
      t.payment_method"

  constructor: (queryStart, queryEnd) ->
    @queryStart = moment(queryStart)
    @queryEnd = moment(queryEnd)

  load: (cb) ->
    queryUtil.batchQuery query, @queryStart, @queryEnd, (err, results) ->
      if err then return cb(err, null)
      gmvByPaymentMethod = {}
      results.forEach (rows) ->
        rows.forEach (row) ->
          currentTotal = gmvByPaymentMethod[row.payment_method] or 0
          gmvByPaymentMethod[row.payment_method] = currentTotal + row.gmv
      cb(null, gmvByPaymentMethod)

module.exports = GmvByPaymentMethod
