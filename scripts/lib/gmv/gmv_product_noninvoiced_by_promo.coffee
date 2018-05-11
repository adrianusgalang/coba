async = require 'async'
moment = require 'moment'
queryUtil = require '../query_util'

class GmvByPromo
  query = "
    select
      case
        when pv.is_reward=1 then 'voucher_cashback'
        when pv.is_reward=0 then 'voucher_potongan'
        when pt.retarget_discount_amount > 0 then 'nego'
        else 'non_promo'
      end as promo_type,
      sum(pt.amount + coalesce(pt.courier_cost, 0) + coalesce(pt.uniq_code, coalesce(pt.service_fee, 0)) + pt.agent_commission_amount + pt.insurance_cost) as gmv
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
      gmvByPromo = {}
      results.forEach (rows) ->
        rows.forEach (row) ->
          currentTotal = gmvByPromo[row.promo_type] or 0
          gmvByPromo[row.promo_type] = currentTotal + row.gmv
      cb(null, gmvByPromo)

module.exports = GmvByPromo
