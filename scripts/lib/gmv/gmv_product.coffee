async = require 'async'
moment = require 'moment'
queryUtil = require '../query_util'

class Gmv
  query = "
    select
      sum(amount + coalesce(courier_cost, 0) + coalesce(uniq_code, coalesce(service_fee, 0)) + agent_commission_amount + insurance_cost) as gmv
    from
      payment_transactions
    where
      paid_at >= ?
      and paid_at < ?
      and fake = 0"

  constructor: (queryStart, queryEnd) ->
    @queryStart = moment(queryStart)
    @queryEnd = moment(queryEnd)

  load: (cb) ->
    queryUtil.batchQuery query, @queryStart, @queryEnd, (err, results) =>
      if err then return cb(err, null)
      reduceFunc = (total, rows) ->
        total + rows[0].gmv
      cb(null, results.reduce(reduceFunc, 0))

module.exports = Gmv
