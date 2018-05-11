queryUtil = require '../query_util'
moment = require 'moment'

class GmvByPaymentMethod
  query = "
    select
      payment_method,
      sum(amount + coalesce(service_fee, 0)) as gmv
    from
      payment_game_voucher_transactions
    where amount<5e8 AND
      created_at >= ?
      and created_at < ?
    group by
      payment_method"

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
