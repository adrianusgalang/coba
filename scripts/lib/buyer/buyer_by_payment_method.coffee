queryUtil = require '../query_util'
async = require '../async'
moment = require 'moment'

class Buyer
  queryUser = (paymentMethod) ->
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
        and payment_method = '#{paymentMethod}'
    "
  queryQuickBuyer = (paymentMethod) ->
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
        and payment_method = '#{paymentMethod}'
    "

  loadQuery = (query, queryStart, queryEnd, cb) ->
    queryUtil.batchQuery query, queryStart, queryEnd, (err, res) ->
      if err then return cb(err, null)
      reduceFunc = (total, rows) ->
        rows.forEach (row) ->
          total.add(Number(row.buyer_id))
        total
      cb(null, res.reduce(reduceFunc, new Set).size)

  loadQueryFunc = (paymentMethods, queryFunc, queryStart, queryEnd, cb) ->
    tasks = {}
    paymentMethods.forEach (paymentMethod) ->
      tasks[paymentMethod] = (cb2) ->
        loadQuery queryFunc(paymentMethod), queryStart, queryEnd, (err, res) ->
          cb2(err, res)
    async.parallelMap tasks, (err, resultMap) ->
      cb(err, resultMap)

  constructor: (queryStart, queryEnd) ->
    @queryStart = moment(queryStart)
    @queryEnd = moment(queryEnd)

  load: (cb) ->
    queryUtil.getPaymentMethods (err, paymentMethods) =>
      async.parallel [
        ((cb2) => loadQueryFunc paymentMethods, queryUser, @queryStart, @queryEnd, (err, res) -> cb2(err, res)),
        ((cb2) => loadQueryFunc paymentMethods, queryQuickBuyer, @queryStart, @queryEnd, (err, res) -> cb2(err, res))
      ], (err, res) ->
        if err then return cb(err, null)
        buyerByPaymentMethod = {}
        paymentMethods.forEach (paymentMethod) ->
          buyer = res[0][paymentMethod] + res[1][paymentMethod]
          if buyer > 0 then buyerByPaymentMethod[paymentMethod] = buyer
        cb(null, buyerByPaymentMethod)

module.exports = Buyer
