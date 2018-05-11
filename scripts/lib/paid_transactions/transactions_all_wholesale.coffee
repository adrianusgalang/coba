async = require 'async'
moment = require 'moment'

sources = [
  require './transactions_wholesale'
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
