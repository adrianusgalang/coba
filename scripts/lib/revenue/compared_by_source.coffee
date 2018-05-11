Model = require './revenue_by_source'
ComparedGrouped = require '../shared/compared_grouped'

class ComparedBySource extends ComparedGrouped
  constructor: (currentStart, currentEnd, otherStart, otherEnd, otherAllEnd) ->
    super(Model, currentStart, currentEnd, otherStart, otherEnd, otherAllEnd)

  toString: (currentPrefix, otherPrefix) ->
    super('source', "#{currentPrefix} revenue", "#{otherPrefix} revenue")

module.exports = ComparedBySource
