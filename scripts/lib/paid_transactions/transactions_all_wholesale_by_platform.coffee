async = require 'async'
moment = require 'moment'

sources = [
  require './transactions_wholesale_by_platform'
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
