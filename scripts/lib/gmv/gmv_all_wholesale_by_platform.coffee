async = require 'async'
moment = require 'moment'

sources = [
  require './gmv_wholesale_by_platform'
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
