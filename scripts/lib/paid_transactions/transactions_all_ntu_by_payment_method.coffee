async = require 'async'
moment = require 'moment'

sources = [
  require './transactions_bukareksa_by_payment_method'
  require './transactions_electricity_by_payment_method'
  require './transactions_external_ad_by_payment_method'
  require './transactions_game_voucher_by_payment_method'
  require './transactions_product_by_payment_method'
  require './transactions_remote_by_payment_method'
  require './transactions_remote_hybrid_by_payment_method'
]

class TransactionsByPaymentMethod
  constructor: (queryStart, queryEnd) ->
    @queryStart = moment(queryStart)
    @queryEnd = moment(queryEnd)

  load: (cb) ->
    tasks = sources.map (Klass) =>
      (cb2) =>
        new Klass(@queryStart, @queryEnd).load (err, res) ->
          cb2(err, res)
    async.parallel tasks, (err, results) ->
      if err then return cb(err, null)
      countByPaymentMethod = {}
      results.forEach (res) ->
        Object.keys(res).forEach (paymentMethod) ->
          count = countByPaymentMethod[paymentMethod] or 0
          countByPaymentMethod[paymentMethod] = count + res[paymentMethod]
      cb(null, countByPaymentMethod)

module.exports = TransactionsByPaymentMethod
