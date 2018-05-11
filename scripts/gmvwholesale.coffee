# Description:
#   GMV wholesale queries related to O2O
#
# Commands:
#   gmvwsl hari ini / ghiwsl - lihat gmv tanpa topup hari ini
#   gmvwsl minggu ini / gmiwsl - lihat gmv tanpa topup minggu ini
#   gmvwsl bulan ini / gbiwsl - lihat gmv tanpa topup bulan ini
#   gmvwsl <t1> - lihat gmv tanggal <t1>. format tanggal DD-MM-YYYY
#   gmvwsl <t1> sd <t2> - lihat gmv dari tanggal <t1> hingga <t2>. format tanggal DD-MM-YYYY
#   gmvwsl hari ini vs <t> / ghiwsl vs <t> - bandingkan gmv wholesale hari ini dan tanggal <t>. format tanggal DD-MM-YYYY
#   gmvwsl <t1> vs <t2> - bandingkan gmv tanpa topup tanggal <t1> dan <t2>. format tanggal DD-MM-YYYY
#   gmvwsl <X>d - lihat gmv tanpa topup <X> hari terakhir serta <X> hari sebelumnya
#   <gmvwsl_command> per platform - tampilkan informasi gmv wholesale per platform
#   <gmvwsl_command> per payment method - tampilkan informasi gmv wholesale per payment method
#
# Notes:
#   copy from gmv.coffee

dateUtil = require('./lib/date_util')
moment = require('moment')

modsRegexpString = '(?:\\s+(?:per|by)\\s+(platform|payment method|product type))?'

usedModel = (groupBy) ->
  switch groupBy
    when 'platform'
      require('./lib/gmv/compared_wholesale_by_platform')
    when 'payment method'
      require('./lib/gmv/compared_wholesale_by_payment_method')
    else
      require('./lib/gmv/compared_wholesale')

sendOutput = (msg, output) ->
  if Array.isArray(output)
    output.forEach (string) -> msg.send(string)
  else
    msg.send(output)

module.exports = (robot) ->
  # g(h/m/b)iwsl
  robot.hear new RegExp(
    '^(?:g(h|m|b)iwsl|gmvwsl\\s+(hari|minggu|bulan)\\s+ini)' + modsRegexpString + '$', 'im'
  ), (msg) ->
    Model = usedModel(msg.match[3])
    console.log(msg.match)

    t = dateUtil.now()
    switch msg.match[1] or msg.match[2]
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

  # gmvwsl tanggal (s/d tanggal)
  robot.hear new RegExp(
    '^gmvwsl\\s+(?:tanggal\\s+)?(' +
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

  # gmvwsl hari ini/ghiwsl vs tanggal
  robot.hear new RegExp(
    '^(?:ghiwsl|gmvwsl\\s+hari\\s+ini)\\s+vs\\s(' +
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

  # gmvwsl tanggal vs tanggal
  robot.hear new RegExp(
    '^gmvwsl\\s+(?:tanggal\\s+)?(' +
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

  # gmvwsl Xd
  robot.hear new RegExp(
    '^gmvwsl\\s+(\\d+)d' +
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
