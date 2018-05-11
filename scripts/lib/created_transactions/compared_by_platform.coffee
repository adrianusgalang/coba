Model = require './transactions_all_by_platform'
ComparedGrouped = require '../shared/compared_grouped'

class ComparedByPlatform extends ComparedGrouped
  constructor: (currentStart, currentEnd, otherStart, otherEnd, otherAllEnd) ->
    super(Model, currentStart, currentEnd, otherStart, otherEnd, otherAllEnd)

  toString: (currentPrefix, otherPrefix) ->
    super('platform', "#{currentPrefix} created trxs", "#{otherPrefix} created trxs")

module.exports = ComparedByPlatform
