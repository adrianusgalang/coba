queryUtil = require '../query_util'
async = require 'async'
moment = require 'moment'

class Buyer
  queryUser = "
    select
      distinct buyer_id
    from
      payment_transactions
    where
      paid_at >= ?
      and paid_at < ?
      and fake = 0
      and buyer_type = 'User'"
  queryQuickBuyer = "
    select
      distinct buyer_id
    from
      payment_transactions
    where
      paid_at >= ?
      and paid_at < ?
      and fake = 0
      and buyer_type = 'QuickBuyer'"

  loadQuery = (query, queryStart, queryEnd, cb) ->
    queryUtil.batchQuery query, queryStart, queryEnd, (err, res) ->
      if err then return cb(err, null)
      reduceFunc = (total, rows) ->
        rows.forEach (row) ->
          total.add(Number(row.buyer_id))
        total
      cb(null, res.reduce(reduceFunc, new Set).size)

  constructor: (queryStart, queryEnd) ->
    @queryStart = moment(queryStart)
    @queryEnd = moment(queryEnd)

  load: (cb) ->
    async.parallel [
      ((cb2) => loadQuery queryUser, @queryStart, @queryEnd, (err, result) -> cb2(err, result)),
      ((cb2) => loadQuery queryQuickBuyer, @queryStart, @queryEnd, (err, result) -> cb2(err, result))
    ], (err, res) ->
      if err then return cb(err, null)
      cb(null, res[0] + res[1])

module.exports = Buyer
