queryUtil = require '../query_util'
async = require 'async'
moment = require 'moment'

class Buyer
  queryUser = (platform) ->
    "
      select
        distinct buyer_id
      from
        payment_transactions
      where
        paid_at >= ?
        and paid_at < ?
        and fake = 0
        and buyer_type = 'User'
        and buyer_id not in (21985064,16595749,21985064,9341368)
        and agent_commission_amount <= 0
        and created_on = '#{platform}'
    "
  queryQuickBuyer = (platform) ->
    "
      select
        distinct buyer_id
      from
        payment_transactions
      where
        paid_at >= ?
        and paid_at < ?
        and fake = 0
        and buyer_type = 'QuickBuyer'
        and agent_commission_amount <= 0
        and created_on = '#{platform}'
    "
  queryCae = "
    select
      distinct buyer_id
    from
      payment_transactions
    where
      paid_at >= ?
      and paid_at < ?
      and fake = 0
      and buyer_type = 'User'
      and buyer_id in (21985064,16595749,21985064,9341368)"
  queryO2oUser = "
    select
      distinct buyer_id
    from
      payment_transactions
    where
      paid_at >= ?
      and paid_at < ?
      and fake = 0
      and agent_commission_amount > 0
      and buyer_type = 'User'"
  queryO2oQuickBuyer = "
    select
      distinct buyer_id
    from
      payment_transactions
    where
      paid_at >= ?
      and paid_at < ?
      and fake = 0
      and agent_commission_amount > 0
      and buyer_type = 'QuickBuyer'"

  loadQuery = (query, queryStart, queryEnd, cb) ->
    queryUtil.batchQuery query, queryStart, queryEnd, (err, res) ->
      if err then return cb(err, null)
      reduceFunc = (total, rows) ->
        rows.forEach (row) ->
          total.add(Number(row.buyer_id))
        total
      cb(null, res.reduce(reduceFunc, new Set).size)

  loadQueryFunc = (platforms, queryFunc, queryStart, queryEnd, cb) ->
    tasks = {}
    platforms.forEach (platform) ->
      tasks[platform] = (cb2) ->
        loadQuery queryFunc(platform), queryStart, queryEnd, (err, res) ->
          cb2(err, res)
    async.parallelMap tasks, (err, resultMap) ->
      cb(err, resultMap)

  constructor: (queryStart, queryEnd) ->
    @queryStart = moment(queryStart)
    @queryEnd = moment(queryEnd)

  load: (cb) ->
    queryUtil.getPlatforms (err, platforms) =>
      async.parallel [
        ((cb2) => loadQueryFunc platforms, queryUser, @queryStart, @queryEnd, (err, res) -> cb2(err, res)),
        ((cb2) => loadQueryFunc platforms, queryQuickBuyer, @queryStart, @queryEnd, (err, res) -> cb2(err, res)),
        ((cb2) => loadQuery queryCae, @queryStart, @queryEnd, (err, res) -> cb2(err, res)),
        ((cb2) => loadQuery queryO2oUser, @queryStart, @queryEnd, (err, res) -> cb2(err, res)),
        ((cb2) => loadQuery queryO2oQuickBuyer, @queryStart, @queryEnd, (err, res) -> cb2(err, res))
      ], (err, res) ->
        if err then return cb(err, null)
        data = {}
        platforms.forEach (platform) ->
          buyer = res[0][platform] + res[1][platform]
          if buyer > 0 then data[platform] = buyer
        cae = res[2]
        if cae then data.cae = cae
        o2o = res[3] + res[4]
        if o2o then data.o2o = o2o
        cb(null, data)

module.exports = Buyer
