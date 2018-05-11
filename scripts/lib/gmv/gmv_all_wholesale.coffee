async = require 'async'
moment = require 'moment'

sources = [
  require './gmv_wholesale'
]

class Gmv
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
      gmv = 0
      results.forEach (res) ->
        gmv += res
      cb(null, gmv)

module.exports = Gmv
