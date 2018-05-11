Model = require './buyer_by_payment_method'
ComparedGrouped = require '../shared/compared_grouped'

class ComparedByPaymentMethod extends ComparedGrouped
  constructor: (currentStart, currentEnd, otherStart, otherEnd, otherAllEnd) ->
    super(Model, currentStart, currentEnd, otherStart, otherEnd, otherAllEnd)

  toString: (currentPrefix, otherPrefix) ->
    super('payment method', "#{currentPrefix} distinct buyers", "#{otherPrefix} distinct buyers")

module.exports = ComparedByPaymentMethod
