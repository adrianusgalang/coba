Model = require './transactions_all_by_product_type'
ComparedGrouped = require '../shared/compared_grouped'

class ComparedByProductType extends ComparedGrouped
  constructor: (currentStart, currentEnd, otherStart, otherEnd, otherAllEnd) ->
    super(Model, currentStart, currentEnd, otherStart, otherEnd, otherAllEnd)

  toString: (currentPrefix, otherPrefix) ->
    super('product type', "#{currentPrefix} created trxs", "#{otherPrefix} created trxs")

module.exports = ComparedByProductType
