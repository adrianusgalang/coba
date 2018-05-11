queryUtil = require '../query_util'
moment = require 'moment'

class GmvByPaymentMethod
  query = "
    select
      t.payment_method,
      sum(dm.amount) as gmv
    from
      deposit_mutations dm
      inner JOIN deposit_topups t ON t.id=dm.topup_id
    where
      dm.action IN ('user_topup','topup') AND dm.amount>0
      and dm.created_at >= ?
      and dm.created_at < ?
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
