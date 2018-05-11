async = require 'async'
moment = require 'moment'

sources = [
  require './transactions_product_invoiced_by_promo'
  require './transactions_product_noninvoiced_by_promo'
]

class TransactionsByPromo
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
      countByPromo = {}
      results.forEach (res) ->
        Object.keys(res).forEach (promo) ->
          count = countByPromo[promo] or 0
          countByPromo[promo] = count + res[promo]
      cb(null, countByPromo)

module.exports = TransactionsByPromo
