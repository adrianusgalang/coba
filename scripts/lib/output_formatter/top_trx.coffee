require '../numbers'
Table = require 'cli-table2'

module.exports =
  dbError: ->
    'Error while connecting to database.'

  topTrx: (transactions, prefix) ->
    table = new Table(
      head: ['id', 'gmv', 'coded_amount', 'invoiceable_type', 'paid_at','buyer_id', 'buyer_type', 'buyer_username', 'payment_method', 'created_on', 'voucher_code']
    )

    transactions.forEach (transaction) ->
      row = [
        transaction.id,
        { hAlign: 'right', content: transaction.gmv.toRp() },
        { hAlign: 'right', content: transaction.coded_amount.toRp() },
        transaction.invoiceable_type,
        transaction.paid_at,
        transaction.buyer_id,
        transaction.buyer_type,
        transaction.buyer_username,
        transaction.payment_method,
        transaction.created_on,
        transaction.voucher_code
      ]
      table.push row

    "```#{table.toString()}```"
