# Description:
#   GMV queries
#
# Commands:
#   gmv hari ini / ghi - lihat gmv hari ini
#   gmv minggu ini / gmi - lihat gmv minggu ini (mulai hari jumat)
#   gmv bulan ini / gbi - lihat gmv bulan ini
#   gmv <t1> - lihat gmv dari tanggal <t1> hingga sekarang. format tanggal DD-MM-YYYY / Xdago
#   gmv <t1> sd <t2> - lihat gmv dari tanggal <t1> hingga <t2>. format tanggal DD-MM-YYYY / Xdago
#   gmv <t1> vs <t2> - bandingkan gmv tanggal <t1> dan <t2>. format tanggal DD-MM-YYYY / Xdago
#   gmv <X>d - lihat gmv <X> hari terakhir serta <X> hari sebelumnya
#   gmv hari ini vs <t> / ghi vs <t> - bandingkan gmv hari ini dan tanggal <t>. format tanggal DD-MM-YYYY / Xdago
#   <gmv_command> per platform - tampilkan informasi gmv per platform
#   <gmv_command> per payment method - tampilkan informasi gmv per platform
#   <gmv_command> per product type - tampilkan informasi gmv per product type
# Author:
#   ardfard

auth = require('./lib/auth')
dateUtil = require('./lib/date_util')
moment = require('moment')
cronJob = require('cron').CronJob

modsRegexpString = '(?:\\s+(?:per|by)\\s+(platform|payment method|product type|promo))?'

usedModel = (groupBy) ->
  switch groupBy
    when 'platform'
      require('./lib/gmv/compared_by_platform')
    when 'payment method'
      require('./lib/gmv/compared_by_payment_method')
    when 'product type'
      require('./lib/gmv/compared_by_product_type')
    when 'promo'
      require('./lib/gmv/compared_by_promo')
    else
      require('./lib/gmv/compared')

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

  tz = 'Asia/Jakarta'
  new cronJob('0 59 8,11,14,17,20,23 * * *', (-> reportTodayGmv()), null, true, tz)
  new cronJob('0 0 10,12,14,16,18,20 * * 1-5', (-> reportTodayGmv('platform')), null, true, tz)

  # ghi / gmi / gbi
  robot.hear new RegExp(
    '^(?:g(h|m|b)i|gmv\\s+(hari|minggu|bulan)\\s+ini)' +
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
    '^(?:ghi|gmv\\s+hari\\s+ini)\\s+vs\\s(' +
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
    '^gmv\\s+(?:tanggal\\s+)?(' +
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
    '^gmv\\s+(\\d+)d' +
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
    '^gmv\\s+(?:tanggal\\s+)?(' +
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
