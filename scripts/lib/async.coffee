async = require 'async'

async.parallelMap = (taskMap, cb) ->
  keys = Object.keys(taskMap)
  ret = {}
  tasks = keys.map (label) -> taskMap[label]
  @parallel tasks, (err, results) ->
    if err then return cb(err, null)
    results.forEach (result, index) ->
      ret[keys[index]] = result
    cb(null, ret)

module.exports = async
