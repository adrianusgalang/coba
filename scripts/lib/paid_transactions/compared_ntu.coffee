Model = require './transactions_all_ntu'
ComparedSimple = require '../shared/compared_simple'

class Compared extends ComparedSimple
  constructor: (currentStart, currentEnd, otherStart, otherEnd, otherAllEnd) ->
    super(Model, currentStart, currentEnd, otherStart, otherEnd, otherAllEnd)

  toString: (currentPrefix, otherPrefix) ->
    super("#{currentPrefix} trxs", "#{otherPrefix} trxs")

module.exports = Compared
