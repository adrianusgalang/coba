async = require 'async'
moment = require 'moment'

sources = [
  require './gmv_bukareksa_by_payment_method'
  require './gmv_electricity_by_payment_method'
  require './gmv_external_ad_by_payment_method'
  require './gmv_game_voucher_by_payment_method'
  require './gmv_product_by_payment_method'
  require './gmv_remote_by_payment_method'
  require './gmv_remote_hybrid_by_payment_method'
]

class GmvByPaymentMethod
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
      gmvByPaymentMethod = {}
      results.forEach (res) ->
        Object.keys(res).forEach (paymentMethod) ->
          gmv = gmvByPaymentMethod[paymentMethod] or 0
          gmvByPaymentMethod[paymentMethod] = gmv + res[paymentMethod]
      cb(null, gmvByPaymentMethod)

module.exports = GmvByPaymentMethod
