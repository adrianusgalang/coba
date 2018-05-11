Model = require './revenue'
ComparedSimple = require '../shared/compared_simple'

class Compared extends ComparedSimple
  constructor: (currentStart, currentEnd, otherStart, otherEnd, otherAllEnd) ->
    #console.log("masuk super compared 1")
    super(Model, currentStart, currentEnd, otherStart, otherEnd, otherAllEnd)
    #console.log("#{Model} #{currentEnd} #{otherStart} #{otherEnd} #{otherAllEnd}")

  toString: (currentPrefix, otherPrefix) ->
    #console.log("masuk super compared 3")
    super("#{currentPrefix} revenue", "#{otherPrefix} revenue")
    #console.log("masuk super compared 4")

module.exports = Compared
