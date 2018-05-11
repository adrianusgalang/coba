moment = require 'moment'
async = require '../async'

class ComparedBase
  constructor: (Model, currentStart, currentEnd, otherStart, otherEnd, otherAllEnd) ->
    @Model = Model
    @currentStart = moment(currentStart)
    @currentEnd = moment(currentEnd)
    if otherStart then @otherStart = moment(otherStart)
    if otherEnd then @otherEnd = moment(otherEnd)
    if otherAllEnd then @otherAllEnd = moment(otherAllEnd)

  load: (cb) ->
    tasks =
      current: (cb2) =>
        new @Model(@currentStart, @currentEnd).load (err, result) ->
          cb2(err, result)
    if @otherStart and @otherEnd then tasks.other = (cb2) =>
      new @Model(@otherStart, @otherEnd).load (err, result) ->
        cb2(err, result)
    if @otherStart and @otherAllEnd then tasks.otherAll = (cb2) =>
      new @Model(@otherStart, @otherAllEnd).load (err, result) ->
        cb2(err, result)
    async.parallelMap tasks, (err, result) =>
      if err then return cb(err, null)
      @current = result.current
      if result.other then @other = result.other
      if result.otherAll then @otherAll = result.otherAll
      cb(err, this)

module.exports = ComparedBase
