Model = require './buyer'
ComparedSimple = require '../shared/compared_simple'

class Compared extends ComparedSimple
  constructor: (currentStart, currentEnd, otherStart, otherEnd, otherAllEnd) ->
    super(Model, currentStart, currentEnd, otherStart, otherEnd, otherAllEnd)

  toString: (currentPrefix, otherPrefix) ->
    super("#{currentPrefix} distinct buyers", "#{otherPrefix} distinct buyers")

module.exports = Compared
