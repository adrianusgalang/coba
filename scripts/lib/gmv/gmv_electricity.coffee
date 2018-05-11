queryUtil = require '../query_util'
moment = require 'moment'

class Gmv
  query = "
    select
      sum(amount + coalesce(service_fee, 0)) as gmv
    from
      payment_electricity_transactions
    where
      paid_at >= ?
      and paid_at < ?"

  constructor: (queryStart, queryEnd) ->
    @queryStart = moment(queryStart)
    @queryEnd = moment(queryEnd)

  load: (cb) ->
    queryUtil.batchQuery query, @queryStart, @queryEnd, (err, results) ->
      if err then return cb(err, null)
      reduceFunc = (total, rows) -> total + rows[0].gmv
      cb(null, results.reduce(reduceFunc, 0))

module.exports = Gmv
