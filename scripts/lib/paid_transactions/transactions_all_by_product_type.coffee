async = require '../async'
moment = require 'moment'

sources =
  bukaiklan:    require './transactions_external_ad'
  bukareksa:    require './transactions_bukareksa'
  electricity:  require './transactions_electricity'
  game_voucher: require './transactions_game_voucher'
  payment_trx:  require './transactions_product_by_product_type'
  remote_trx:   require './transactions_remote_by_product_type'
  remote_hybrid_trx:   require './transactions_remote_hybrid_by_product_type'
  topup:        require './transactions_topup'
  topup_credit:        require './transactions_topup_credit'

class TransactionsByProductType
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
      countByProductType = {}
      Object.keys(results).forEach (key) ->
        res = results[key]
        if res.constructor == Object
          Object.keys(res).forEach (productType) ->
            countByProductType[productType] = res[productType]
        else
          countByProductType[key] = res
      cb(null, countByProductType)

module.exports = TransactionsByProductType
