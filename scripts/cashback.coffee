# Description:
#   Rewards cashback excluding topup credits
#
# Commands:
#   cashback - tampilkan cashback hari ini
#   cashback t1 - tampilkan cashback pada tanggal t1. Format tanggal DD-MM-YYYY
#   cashback t1 sd t2 - tampilkan cashback sejak tanggal t1 hingga tanggal t2. Format tanggal DD-MM-YYYY

dateUtil = require('./lib/date_util')
outputFormatter = require('./lib/output_formatter/general')
mysql = require('./lib/mysql')
moment = require('moment')
require('./lib/numbers')

queryString = (startDate, endDate) ->
  "
    SELECT 
      count(id) as trx,
      sum(amount) AS total_amount
    FROM deposit_rewards
    WHERE rewards_topup_id is null and
      created_at >= '#{moment(startDate).utc().format('YYYY-MM-DD HH:mm:ss')}' and
      created_at < '#{moment(endDate).add(1, 'day').utc().format('YYYY-MM-DD HH:mm:ss')}'
  "

outputFormat = (startDate, endDate, rows) ->
    "Cashback from #{startDate.format('DD-MM-YYYY')} to #{endDate.format('DD-MM-YYYY')}\n" +
    "Cashback Amount: *#{rows[0].total_amount.toRp()}*\n" +
    "Transactions: #{rows[0].trx.toNum()}"

module.exports = (robot) ->
  robot.hear new RegExp(
    '^cashback(?:\\s+(?:tanggal|tgl))?(?:\\s+(' +
    dateUtil.dateRegexp().source +
    '))?(?:\\s+sd)?(?:\\s+(' +
    dateUtil.dateRegexp().source +
    '))?$'
    , 'im'
  ), (msg) ->
    if msg.match[1]
      startDate = dateUtil.parseDate(msg.match[1])
      if startDate == null then return msg.send('Invalid date')
    else
      startDate = dateUtil.today()
    if msg.match[2]
      endDate = dateUtil.parseDate(msg.match[2])
      if startDate == null then return msg.send('Invalid date')
    else
      endDate = startDate

    mysql.getConnection (err, connection) ->
      if err then return msg.send(outputFormatter.dbError())
      connection.query queryString(startDate, endDate), (err, rows) ->
        if err then return msg.send(outputFormatter.dbError())
        msg.send(outputFormat(startDate, endDate, rows))
