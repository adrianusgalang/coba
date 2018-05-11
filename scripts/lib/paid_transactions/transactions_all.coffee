async = require 'async'
moment = require 'moment'

sources = [
  require './transactions_bukareksa'
  require './transactions_electricity'
  require './transactions_external_ad'
  require './transactions_game_voucher'
  require './transactions_product'
  require './transactions_remote'
  require './transactions_remote_hybrid'
  require './transactions_topup'
  require './transactions_topup_credit'
]

class Transactions
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
      count = 0
      results.forEach (res) ->
        count += res
      cb(null, count)

module.exports = Transactions
