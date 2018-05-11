# Description:
#   Created GMV queries
#
# Commands:
#   cmv hari ini / ghi - lihat created gmv hari ini
#   cmv minggu ini / gmi - lihat created gmv minggu ini (mulai hari jumat)
#   cmv bulan ini / gbi - lihat created gmv bulan ini
#   cmv <t1> - lihat created gmv dari tanggal <t1> hingga sekarang. format tanggal DD-MM-YYYY / Xdago
#   cmv <t1> sd <t2> - lihat created gmv dari tanggal <t1> hingga <t2>. format tanggal DD-MM-YYYY / Xdago
#   cmv <t1> vs <t2> - bandingkan created gmv tanggal <t1> dan <t2>. format tanggal DD-MM-YYYY / Xdago
#   cmv <X>d - lihat created gmv <X> hari terakhir serta <X> hari sebelumnya
#   cmv hari ini vs <t> / ghi vs <t> - bandingkan created gmv hari ini dan tanggal <t>. format tanggal DD-MM-YYYY / Xdago
#   <cmv_command> per platform - tampilkan informasi created gmv per platform
#   <cmv_command> per payment method - tampilkan informasi created gmv per platform
#   <cmv_command> per product type - tampilkan informasi created gmv per product type
# Author:
#   teguhn

auth = require('./lib/auth')
dateUtil = require('./lib/date_util')
moment = require('moment')
cronJob = require('cron').CronJob

modsRegexpString = '(?:\\s+(?:per|by)\\s+(platform|payment method|product type))?'

usedModel = (groupBy) ->
  switch groupBy
    when 'platform'
      require('./lib/created_gmv/compared_by_platform')
    when 'payment method'
      require('./lib/created_gmv/compared_by_payment_method')
    when 'product type'
      require('./lib/created_gmv/compared_by_product_type')
    else
      require('./lib/created_gmv/compared')

sendOutput = (msg, output) ->
  if Array.isArray(output)
    output.forEach (string) -> msg.send(string)
  else
    msg.send(output)

module.exports = (robot) ->

  reportTodayGmv = (groupBy) ->
    Model = usedModel(groupBy)
    t = dateUtil.now()
    currentStart = moment(t).startOf('day')
    currentEnd = moment(t)
    lastStart = moment(t).subtract(7, 'days').startOf('day')
    lastEnd = moment(t).subtract(7, 'days')
    lastAllEnd = moment(t).subtract(6, 'days').startOf('day')

    model = new Model(currentStart, currentEnd, lastStart, lastEnd, lastAllEnd)
    model.load (err, result) ->
      if err then return robot.messageRoom(auth.dataChannelId, err)
      if Array.isArray(output = result.toString('today', 'last week'))
        output.forEach (string) ->
          robot.messageRoom(auth.dataChannelId, string)
      else
        robot.messageRoom(auth.dataChannelId, output)

#  tz = 'Asia/Jakarta'
#  new cronJob('0 59 8,11,14,17,20,23 * * *', (-> reportTodayGmv()), null, true, tz)
#  new cronJob('0 0 10,12,14,16,18,20 * * 1-5', (-> reportTodayGmv('platform')), null, true, tz)

  # thi / tmi / tbi
  robot.hear new RegExp(
    '^(?:c(h|m|b)i|cmv\\s+(hari|minggu|bulan)\\s+ini)' +
    modsRegexpString + '$'
    , 'im'
  ), (msg) ->
    Model = usedModel(msg.match[3])

    t = dateUtil.now()
    period = msg.match[1] or msg.match[2]
    switch period
      when 'h', 'hari'
        currentStart = moment(t).startOf('day')
        currentEnd = moment(t)
        lastStart = moment(t).subtract(7, 'days').startOf('day')
        lastEnd = moment(t).subtract(7, 'days')
        lastAllEnd = moment(t).subtract(6, 'days').startOf('day')
        reportCurrentPrefix = 'today'
        reportLastPrefix = 'last week'
      when 'm', 'minggu'
        currentStart = moment(t).day( - 2).startOf('day')
        currentEnd = moment(t)
        lastStart = moment(t).day( - 9).startOf('day')
        lastEnd = moment(t).subtract(7, 'days')
        lastAllEnd = moment(currentStart)
        reportCurrentPrefix = 'this week'
        reportLastPrefix = 'last week'
      when 'b', 'bulan'
        currentStart = moment(t).startOf('month')
        currentEnd = moment(t)
        reportCurrentPrefix = 'this month'

    model = new Model(currentStart, currentEnd, lastStart, lastEnd, lastAllEnd)
    model.load (err, result) ->
      if err then return msg.send(err)
      sendOutput(msg, result.toString(reportCurrentPrefix, reportLastPrefix))

  # ghi vs tanggal
  robot.hear new RegExp(
    '^(?:chi|cmv\\s+hari\\s+ini)\\s+vs\\s(' +
    dateUtil.dateRegexp().source +
    ')' + modsRegexpString + '$'
    , 'im'
  ), (msg) ->
    Model = usedModel(msg.match[2])

    vsStart = dateUtil.parseDate(msg.match[1])
    if vsStart == null then return msg.send('Invalid date')

    currentEnd = dateUtil.now()
    currentStart = moment(currentEnd).startOf('day')
    vsEnd = moment(vsStart)
    vsEnd.seconds(currentEnd.second())
    vsEnd.minutes(currentEnd.minute())
    vsEnd.hours(currentEnd.hour())
    vsAllEnd = moment(vsStart).add(1, 'day')

    model = new Model(currentStart, currentEnd, vsStart, vsEnd, vsAllEnd)
    model.load (err, result) ->
      if err then return msg.send(err)
      sendOutput(msg, result.toString('today', msg.match[1]))

  # gmv tanggal vs tanggal
  robot.hear new RegExp(
    '^cmv\\s+(?:tanggal\\s+)?(' +
    dateUtil.dateRegexp().source +
    ')\\s+vs\\s+(' +
    dateUtil.dateRegexp().source +
    ')' + modsRegexpString + '$'
    , 'im'
  ), (msg) ->
    Model = usedModel(msg.match[3])

    start = dateUtil.parseDate(msg.match[1])
    if start == null then return msg.send('Invalid date')
    vsStart = dateUtil.parseDate(msg.match[2])
    if vsStart == null then return msg.send('Invalid date')

    end = moment(start).add(1, 'day')
    vsEnd = moment(vsStart).add(1, 'day')

    model = new Model(start, end, vsStart, vsEnd, vsEnd)
    model.load (err, result) ->
      if err then return msg.send(err)
      sendOutput(msg, result.toString(msg.match[1], msg.match[2]))

  # gmv Xd
  robot.hear new RegExp(
    '^cmv\\s+(\\d+)d' +
    modsRegexpString + '$'
    , 'im'
  ), (msg) ->
    Model = usedModel(msg.match[2])

    dayInterval = parseInt(msg.match[1])
    lastDayInterval = dateUtil.now().subtract(dayInterval, 'days')
    lastTwoDayInterval = dateUtil.now().subtract(dayInterval * 2, 'days')

    model = new Model(lastDayInterval, dateUtil.now(), lastTwoDayInterval, lastDayInterval)
    model.load (err, result) ->
      if err then return msg.send(err)
      sendOutput(msg, result.toString("last #{dayInterval} day(s)", 'previous'))

  # gmv tanggal[ sd tanggal]
  robot.hear new RegExp(
    '^cmv\\s+(?:tanggal\\s+)?(' +
    dateUtil.dateRegexp().source +
    ')(?:\\s+sd\\s+(' +
    dateUtil.dateRegexp().source +
    '))?' + modsRegexpString + '$'
    , 'im'
  ), (msg) ->
    Model = usedModel(msg.match[3])

    from = dateUtil.parseDate(msg.match[1])
    if from == null then return msg.send('Invalid date')
    to = dateUtil.parseDate(msg.match[2]) or moment(from)
    if to == null then return msg.send('Invalid date')

    to.add(1, 'day')

    reportPrefix = msg.match[1]
    if msg.match[2] then reportPrefix += " – #{msg.match[2]}"

    model = new Model(from, to)
    model.load (err, result) ->
      if err then return msg.send err
      sendOutput(msg, result.toString(reportPrefix))
