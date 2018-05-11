require '../numbers'
ComparedBase = require './compared_base'
Table = require 'cli-table2'

class ComparedGrouped extends ComparedBase
  load: (cb) ->
    super (err) =>
      if err then return cb(err, null)
      @_current = @current
      @current = (group) -> @_current[group] or 0
      if @other
        @_other = @other
        @other = (group) -> @_other[group] or 0
      if @otherAll
        @_otherAll = @otherAll
        @otherAll = (group) -> @_otherAll[group] or 0
      cb(null, this)

  groups: ->
    groups = new Set()
    Object.keys(@_current).forEach (group) ->
      groups.add(group)
    if @_other then Object.keys(@_other).forEach (group) ->
      groups.add(group)
    if @_otherAll then Object.keys(@_otherAll).forEach (group) ->
      groups.add(group)
    groups

  diff: (group) ->
    @current(group) - @other(group)

  diffPercent: (group) ->
    @diff(group) / @other(group)

  projected: (group) ->
    @current(group) * @otherAll(group) / @other(group)

  currentSum: ->
    reduceFunc = (total, group) => total + @_current[group]
    Object.keys(@_current).reduce(reduceFunc, 0)

  otherSum: ->
    reduceFunc = (total, group) => total + @_other[group]
    Object.keys(@_other).reduce(reduceFunc, 0)

  otherAllSum: ->
    reduceFunc = (total, group) => total + @_otherAll[group]
    Object.keys(@_otherAll).reduce(reduceFunc, 0)

  diffSum: ->
    @currentSum() - @otherSum()

  diffPercentSum: ->
    @diffSum() / @otherSum()

  projectedSum: ->
    @currentSum() * @otherAllSum() / @otherSum()

  currentString: (group) ->
    @current(group).toNum()

  otherString: (group) ->
    @other(group).toNum()

  diffString: (group) ->
    "#{@diff(group).toNum()} (#{@diffPercent(group).toPercent()})"

  projectedString: (group) ->
    @projected(group).toNum()

  currentSumString: ->
    @currentSum().toNum()

  otherSumString: ->
    @otherSum().toNum()

  diffSumString: ->
    "#{@diffSum().toNum()} (#{@diffPercentSum().toPercent()})"

  projectedSumString: ->
    @projectedSum().toNum()

  toString: (groupBy, currentPrefix, otherPrefix) ->
    outputs = []
    counter = 0
    header = [groupBy, "#{currentPrefix}"]
    if @_other
      header.push("diff with #{otherPrefix}")
    if @_otherAll
      header.push("projected #{currentPrefix}")
    table = new Table(head: header)

    @groups().forEach (group) =>
      row = [group, @currentString(group) ]
      if @_other
        row.push(@diffString(group))
      if @_otherAll
        row.push(@projectedString(group))
      table.push(row)
      counter += 1
      if counter is 5
        outputs.push("```#{table.toString()}```")
        counter = 0
        table = new Table(head: header)

    totalRow = ['TOTAL', @currentSumString()]
    if @_other
      totalRow.push(@diffSumString())
    if @_otherAll
      totalRow.push(@projectedSumString())
    table.push(totalRow)

    outputs.push("```#{table.toString()}```")
    outputs

module.exports = ComparedGrouped
