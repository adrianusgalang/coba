async = require 'async'
moment = require 'moment'

sources = [
  require './gmv_product_invoiced_by_promo'
  require './gmv_product_noninvoiced_by_promo'
]

class GmvByPromo
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
      gmvByPromo = {}
      results.forEach (res) ->
        Object.keys(res).forEach (promo) ->
          gmv = gmvByPromo[promo] or 0
          gmvByPromo[promo] = gmv + res[promo]
      cb(null, gmvByPromo)

module.exports = GmvByPromo
