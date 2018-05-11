Model = require './transactions_all_by_promo'
ComparedGrouped = require '../shared/compared_grouped'

class ComparedByPromo extends ComparedGrouped
  constructor: (currentStart, currentEnd, otherStart, otherEnd, otherAllEnd) ->
    super(Model, currentStart, currentEnd, otherStart, otherEnd, otherAllEnd)

  toString: (currentPrefix, otherPrefix) ->
    super('promo', "#{currentPrefix} trxs", "#{otherPrefix} trxs")

module.exports = ComparedByPromo
