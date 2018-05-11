require '../numbers'
ComparedBase = require './compared_base'

class ComparedSimple extends ComparedBase
  diff: ->
    @current - @other

  diffPercent: ->
    @diff() / @other

  projected: ->
    @current  * @otherAll / @other

  currentString: ->
    @current.toNum()

  otherString: ->
    @other.toNum()

  diffString: ->
    "#{@diff().toNum()} (#{@diffPercent().toPercent()})"

  projectedString: ->
    @projected().toNum()

  toString: (currentPrefix, otherPrefix)->
    ret = ["#{currentPrefix}: #{@currentString()}"]
    if @other
      ret.push "#{otherPrefix}: #{@otherString()}"
      ret.push "diff: #{@diffString()}"
    if @otherAll
      ret.push "projected #{currentPrefix}: #{@projectedString()}"
    ret.join("\n")

module.exports = ComparedSimple
