# Description:
#   Transaction queries
#
# Commands:
#   top <X> trx - tampilkan X (max: 100) transaksi terbesar hari ini.
#   top <X> trx <t1> - tampilkan X (max: 100) transaksi terbesar pada tanggal t1. Format tanggal DD-MM-YYYY / Xdago

dateUtil = require('./lib/date_util')
mysql = require('./lib/mysql')
outputFormatter = require('./lib/output_formatter/top_trx')
async = require('async')
moment = require('moment')

topTrxQueryString = (date, limit) ->
  "
    select
      pi.id,
      (coded_amount -COALESCE(uniq_code,0) +COALESCE(service_fee,0) + voucher_amount + promo_payment_amount + deposit_reduction_amount) as gmv,
      coded_amount,
      pm.invoiceable_type,
      pm.invoiceable_id,
      date_format(paid_at+interval 7 hour,'%d-%m-%Y %T') as paid_at,
      buyer_id,
      buyer_type,
      pi.payment_method,
      created_on,
      pv.campaign_code
    from
      payment_invoices pi
      join payment_invoiceable_mappers pm ON pm.invoice_id=pi.id
      left join promo_vouchers pv  on pv.trx_id=pi.id and pv.trx_type='Payment::Invoice'
    where
      paid_at >= '#{moment(date).utc().format('YYYY-MM-DD HH:mm:ss')}' and
      paid_at < '#{moment(date).add(1, 'day').utc().format('YYYY-MM-DD HH:mm:ss')}'
    group by pi.id
    order by coded_amount desc
    limit #{limit}
  "

usernameQueryString = (userId) ->
  "
    select
      username
    from
      users
    where
      id = #{userId}
  "

queryTopTrx = (date, limit, cb) ->
  mysql.getConnection (err, connection) ->
    if err then return cb(err, null)
    connection.query topTrxQueryString(date, limit), (err, rows) ->
      if err then return cb(err, null)
      rows = rows.map (row) ->
        id: row.id
        gmv: row.gmv
        coded_amount: row.coded_amount
        invoiceable_type: row.invoiceable_type
        paid_at: row.paid_at
        buyer_id: row.buyer_id
        buyer_type: row.buyer_type
        buyer_username: null
        payment_method: row.payment_method
        created_on: row.created_on
        voucher_code: row.campaign_code
      add_usernames = []
      rows.forEach (row) ->
        if row.buyer_type is 'User'
          add_usernames.push (cb) ->
            connection.query usernameQueryString(row.buyer_id), (err, rows) ->
              if err then return cb(err, null)
              row.buyer_username = rows[0].username
              cb(null, null)
      async.parallel add_usernames, (err, result) ->
        if err then return cb(err, null)
        cb(null, rows)

module.exports = (robot) ->
  robot.hear new RegExp(
    '^top\\s+(\\d+)\\s+(?:trx|transactions?)(?:\\s+(' +
    dateUtil.dateRegexp().source +
    '))?$'
    , 'im'
  ), (msg) ->
    limit = parseInt(msg.match[1])
    if limit > 100 then limit = 100
    if msg.match[2]
      date = dateUtil.parseDate(msg.match[2])
      if date == null then return msg.send('Invalid date')
    else
      date = dateUtil.today()

    queryTopTrx date, limit, (err, rows) ->
      if err then msg.send('Error while querying to database')
      msg.send(outputFormatter.topTrx(rows))
