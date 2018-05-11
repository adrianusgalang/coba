queryUtil = require '../query_util'
moment = require 'moment'

class Gmv
  query = "
    select
      sum(amount) as gmv
    from
      deposit_mutations
    where
      action IN ('user_topup','topup') AND amount>0
      and created_at >= ?
      and created_at < ?"

  constructor: (queryStart, queryEnd) ->
    @queryStart = moment(queryStart)
    @queryEnd = moment(queryEnd)

  load: (cb) ->
    queryUtil.batchQuery query, @queryStart, @queryEnd, (err, results) ->
      if err then return cb(err, null)
      reduceFunc = (total, rows) -> total + rows[0].gmv
      cb(null, results.reduce(reduceFunc, 0))

module.exports = Gmv
