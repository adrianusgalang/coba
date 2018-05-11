Model = require './gmv_all_ntu'
ComparedSimple = require '../shared/compared_simple'
ComparedTransactions = require '../paid_transactions/compared_ntu'

class Compared extends ComparedSimple
  constructor: (currentStart, currentEnd, otherStart, otherEnd, otherAllEnd) ->
    super(Model, currentStart, currentEnd, otherStart, otherEnd, otherAllEnd)

  load: (cb) ->
    super (err) =>
      if err then return cb(err, null)
      @transactions = new ComparedTransactions(@currentStart, @currentEnd, @otherStart, @otherEnd, @otherAllEnd)
      @transactions.load (err) =>
        cb(err, this)

  currentString: ->
    "*#{super}* | T:#{@transactions.currentString()}"

  otherString: ->
    "*#{super}* | T:#{@transactions.otherString()}"

  diffString: ->
    "*#{super}* | T:#{@transactions.diffString()}"

  projectedString: ->
    "*#{super}* | T:#{@transactions.projectedString()}"

  toString: (currentPrefix, otherPrefix) ->
    super("#{currentPrefix} GMV without topup", "#{otherPrefix} GMV without topup")

module.exports = Compared
