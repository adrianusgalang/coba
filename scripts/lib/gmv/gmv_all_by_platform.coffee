async = require 'async'
moment = require 'moment'

sources = [
  require './gmv_bukareksa_by_platform'
  require './gmv_electricity_by_platform'
  require './gmv_external_ad_by_platform'
  require './gmv_game_voucher_by_platform'
  require './gmv_product_by_platform'
  require './gmv_remote_by_platform'
  require './gmv_remote_hybrid_by_platform'
  require './gmv_topup_by_platform'
  require './gmv_topup_credit_by_platform'
]

class GmvByPlatform
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
      gmvByPlatform = {}
      results.forEach (res) ->
        Object.keys(res).forEach (platform) ->
          gmv = gmvByPlatform[platform] or 0
          gmvByPlatform[platform] = gmv + res[platform]
      cb(null, gmvByPlatform)

module.exports = GmvByPlatform
