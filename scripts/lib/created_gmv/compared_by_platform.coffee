Model = require './gmv_all_by_platform'
ComparedGrouped = require '../shared/compared_grouped'
ComparedTransactions = require '../created_transactions/compared_by_platform'

class ComparedByPlatform extends ComparedGrouped
  constructor: (currentStart, currentEnd, otherStart, otherEnd, otherAllEnd) ->
    super(Model, currentStart, currentEnd, otherStart, otherEnd, otherAllEnd)

  load: (cb) ->
    super (err) =>
      if err then return cb(err, null)
      @transactions = new ComparedTransactions(@currentStart, @currentEnd, @otherStart, @otherEnd, @otherAllEnd)
      @transactions.load (err) =>
        cb(err, this)

  currentString: (group) ->
    "#{super(group)} | T:#{@transactions.currentString(group)}"

  otherString: (group) ->
    "#{super(group)} | T:#{@transactions.otherString(group)}"

  diffString: (group) ->
    "#{super(group)} | T:#{@transactions.diffString(group)}"

  projectedString: (group) ->
    "#{super(group)} | T:#{@transactions.projectedString(group)}"

  currentSumString: ->
    "#{super} | T:#{@transactions.currentSumString()}"

  otherSumString: ->
    "#{super} | T:#{@transactions.otherSumString()}"

  diffSumString: ->
    "#{super} | T:#{@transactions.diffSumString()}"

  projectedSumString: ->
    "#{super} | T:#{@transactions.projectedSumString()}"

  toString: (currentPrefix, otherPrefix) ->
    super('platform', "#{currentPrefix} Created GMV", "#{otherPrefix} Created GMV")

module.exports = ComparedByPlatform
