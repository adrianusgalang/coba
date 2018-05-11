async = require '../async'
moment = require 'moment'

sources =
  bukaiklan:          require './gmv_external_ad'
  bukareksa:          require './gmv_bukareksa'
  electricity:        require './gmv_electricity'
  game_voucher:       require './gmv_game_voucher'
  payment_trx:        require './gmv_product_by_product_type'
  remote_trx:         require './gmv_remote_by_product_type'
  remote_hybrid_trx:  require './gmv_remote_hybrid_by_product_type'
  topup:              require './gmv_topup'
  topup_credit:       require './gmv_topup_credit'

class GmvByProductType
  constructor: (queryStart, queryEnd) ->
    @queryStart = moment(queryStart)
    @queryEnd = moment(queryEnd)

  load: (cb) ->
    tasks = {}
    Object.keys(sources).forEach (product_type) =>
      Klass = sources[product_type]
      tasks[product_type] = (cb2) =>
        new Klass(@queryStart, @queryEnd).load (err, res) ->
          cb2(err, res)

    async.parallelMap tasks, (err, results) ->
      if err then return cb(err, null)
      gmvByProductType = {}
      Object.keys(results).forEach (key) ->
        res = results[key]
        if res.constructor == Object
          Object.keys(res).forEach (productType) ->
            gmvByProductType[productType] = res[productType]
        else
          gmvByProductType[key] = res
      cb(null, gmvByProductType)

module.exports = GmvByProductType
