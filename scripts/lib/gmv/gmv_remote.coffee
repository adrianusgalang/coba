queryUtil = require '../query_util'
moment = require 'moment'

class Gmv
  query = "
    select
      sum(t.amount + COALESCE(i.uniq_code,COALESCE(i.service_fee,0))) as gmv
    from
      remote_transactions t
      inner join payment_invoiceable_mappers m
        on t.id = m.invoiceable_id
        and m.invoiceable_type = 'Remote::Transaction'
      inner join payment_invoices i
        on m.invoice_id = i.id
    where
      t.remote_type not in ['bullion-redeem', 'electricity-prepaid'] 
      and t.paid_at >= ?
      and t.paid_at < ?"

  constructor: (queryStart, queryEnd) ->
    @queryStart = moment(queryStart)
    @queryEnd = moment(queryEnd)

  load: (cb) ->
    queryUtil.batchQuery query, @queryStart, @queryEnd, (err, results) ->
      if err then return cb(err, null)
      reduceFunc = (total, rows) -> total + rows[0].gmv
      cb(null, results.reduce(reduceFunc, 0))

module.exports = Gmv
