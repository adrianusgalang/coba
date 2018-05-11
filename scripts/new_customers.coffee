# Description:
#   Number of new customers (marketplace only)
#
# Commands:
#   newcust - tampilkan new customers hari ini
#   newcust t1 - tampilkan new customers pada tanggal t1. Format tanggal DD-MM-YYYY
#   newcust t1 sd t2 - tampilkan new customers sejak tanggal t1 hingga tanggal t2. Format tanggal DD-MM-YYYY

dateUtil = require('./lib/date_util')
outputFormatter = require('./lib/output_formatter/general')
mysql = require('./lib/mysql')
moment = require('moment')
require('./lib/numbers')

queryString = (startDate, endDate) ->
  "
    SELECT 
      count(first_paid_at) as new_customers
    FROM users
    WHERE 
      first_paid_at >= '#{moment(startDate).utc().format('YYYY-MM-DD HH:mm:ss')}' and
      first_paid_at < '#{moment(endDate).add(1, 'day').utc().format('YYYY-MM-DD HH:mm:ss')}'
  "

outputFormat = (startDate, endDate, rows) ->
    "#{rows[0].new_customers.toNum()} new customers from #{startDate.format('DD-MM-YYYY')} to #{endDate.format('DD-MM-YYYY')}"

module.exports = (robot) ->
  robot.hear new RegExp(
    '^(?:newcust|new\\scustomer|new\\scustomers)(?:\\s+(?:tanggal|tgl))?(?:\\s+(' +
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
