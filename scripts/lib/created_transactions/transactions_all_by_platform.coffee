async = require 'async'
moment = require 'moment'

sources = [
  require './transactions_bukareksa_by_platform'
  require './transactions_electricity_by_platform'
  require './transactions_external_ad_by_platform'
  require './transactions_game_voucher_by_platform'
  require './transactions_product_by_platform'
  require './transactions_remote_by_platform'
  require './transactions_remote_hybrid_by_platform'
  require './transactions_topup_by_platform'
  require './transactions_topup_credit_by_platform'
]

class TransactionsByPlatform
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
      countByPlatform = {}
      results.forEach (res) ->
        Object.keys(res).forEach (platform) ->
          count = countByPlatform[platform] or 0
          countByPlatform[platform] = count + res[platform]
      cb(null, countByPlatform)

module.exports = TransactionsByPlatform
