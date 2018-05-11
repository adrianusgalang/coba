queryUtil = require '../query_util'
async = require 'async'
moment = require 'moment'

class TransactionsByPlatform
  query = (queryStart, queryEnd) -> "
    select
      case 
        when
          i.buyer_type = 'User' and i.buyer_id in #{queryUtil.caeID} then 'cae' 
        when
          a.user_id is not null then 'o2o'
        when 
          i.created_on LIKE '2%' OR i.created_on IS NULL THEN 'desktop_web'
        else
          i.created_on
        end as platform,
      count(t.id) as count
    from
      bukareksa_transactions t
      inner join payment_invoiceable_mappers m
        on t.id = m.invoiceable_id
        and m.invoiceable_type = 'Bukareksa::Transaction'
      inner join payment_invoices i
        on m.invoice_id = i.id
      left join virtual_product_agents a
        on i.buyer_id = a.user_id
        and a.deleted = false
        and a.status = 1
    where  t.amount<5e8 AND
      t.transaction_type='subscription' 
      and t.created_at >= '#{queryStart.format('YYYY-MM-DD HH:mm:ss')}'-interval 2 day-interval 7 hour
      and t.created_at < '#{queryEnd.format('YYYY-MM-DD HH:mm:ss')}'+interval 17 hour
    group by
      platform"

  constructor: (queryStart, queryEnd) ->
    @queryStart = moment(queryStart)
    @queryEnd = moment(queryEnd)

  load: (cb) ->
    queryUtil.batchQuery query(@queryStart, @queryEnd), @queryStart, @queryEnd, (err, results) ->
      if err then return cb(err, null)
      countByPlatform = {}
      results.forEach (rows) ->
        rows.forEach (row) ->
          currentTotal = countByPlatform[row.platform] or 0
          countByPlatform[row.platform] = currentTotal + row.count
      cb(null, countByPlatform)

module.exports = TransactionsByPlatform
