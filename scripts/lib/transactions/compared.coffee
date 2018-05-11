Model = require './transactions'
ComparedSimple = require '../shared/compared_simple'

class Compared extends ComparedSimple
  constructor: (currentStart, currentEnd, otherStart, otherEnd, otherAllEnd) ->
    super(Model, currentStart, currentEnd, otherStart, otherEnd, otherAllEnd)

  toString: (currentPrefix, otherPrefix) ->
    super("#{currentPrefix} created trxs", "#{otherPrefix} created trxs")

module.exports = Compared
