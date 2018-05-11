async = require 'async'
moment = require 'moment'
queryUtil = require '../query_util'

class TransactionsByPromo
  query = "
    select
      case
        when pv.is_reward=1 then 'voucher_cashback'
        when pv.is_reward=0 then 'voucher_potongan'
        when pt.retarget_discount_amount > 0 then 'nego'
        else 'non_promo'
      end as promo_type,
      count(*) as count
    from
      payment_transactions pt
      left join promo_vouchers pv on pv.trx_id=pt.id and pv.trx_type='Payment::Transaction'
    where
      pt.fake = 0
      and pt.invoice_id is null
      and pt.seller_id  NOT IN (34102071,17231263,13916224)
      and pt.paid_at >= ?
      and pt.paid_at < ?
    group by promo_type"

  constructor: (queryStart, queryEnd) ->
    @queryStart = moment(queryStart)
    @queryEnd = moment(queryEnd)

  load: (cb) ->
    queryUtil.batchQuery query, @queryStart, @queryEnd, (err, results) =>
      if err then return cb(err, null)
      countByPromo = {}
      results.forEach (rows) ->
        rows.forEach (row) ->
          currentTotal = countByPromo[row.promo_type] or 0
          countByPromo[row.promo_type] = currentTotal + row.count
      cb(null, countByPromo)

module.exports = TransactionsByPromo
