require '../numbers'

module.exports =
  dbError: ->
    'Error while querying to database.'

  bde: (date, transactions, gmv, prefix) ->
    unless prefix then prefix = 'Best day'
    "#{prefix}: #{date.format('DD-MM-YYYY (dddd)')}\n" +
    "GMV: *#{gmv.toRp()}*\n" +
    "Transactions: #{transactions.toNum()}"
