queryUtil = require '../query_util'
moment = require 'moment'

class Transactions
  query = "
    select
      count(t.id) as count
    from
      deposit_rewards_topups t
      inner join payment_invoiceable_mappers m
        on t.id = m.invoiceable_id
        and m.invoiceable_type = 'Deposit::Rewards::Topup'
      inner join payment_invoices i
        on m.invoice_id = i.id
    where t.amount>0 AND
      t.processed_at >= ?
      and t.processed_at < ?"

  constructor: (queryStart, queryEnd) ->
    @queryStart = moment(queryStart)
    @queryEnd = moment(queryEnd)

  load: (cb) ->
    queryUtil.batchQuery query, @queryStart, @queryEnd, (err, results) ->
      if err then return cb(err, null)
      reduceFunc = (total, rows) -> total + rows[0].count
      cb(null, results.reduce(reduceFunc, 0))

module.exports = Transactions
