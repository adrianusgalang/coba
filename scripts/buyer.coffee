# Description:
#   Distinct buyer queries
#
# Commands:
#   buyer hari ini / bhi - lihat distinct buyer hari ini
#   buyer minggu ini / bmi - lihat distinct buyer minggu ini (mulai hari jumat)
#   buyer bulan ini / bbi - lihat distinct buyer bulan ini
#   buyer <t1> - lihat distinct buyer dari tanggal <t1> hingga sekarang. format tanggal DD-MM-YYYY / Xdago
#   buyer <t1> sd <t2> - lihat distinct buyer dari tanggal <t1> hingga <t2>. format tanggal DD-MM-YYYY / Xdago
#   buyer <t1> vs <t2> - bandingkan distinct buyer tanggal <t1> dan <t2>. format tanggal DD-MM-YYYY / Xdago
#   buyer <X>d - lihat distinct buyer <X> hari terakhir serta <X> hari sebelumnya
#   buyer hari ini vs <t> / rhi vs <t> - bandingkan distinct buyer hari ini dan tanggal <t>. format tanggal DD-MM-YYYY / Xdago
#   <buyer_command> per platform - tampilkan informasi buyer per platform
#   <buyer_command> per payment method - tampilkan informasi buyer per payment method
# Author:
#   ardfard

dateUtil = require('./lib/date_util')
moment = require('moment')

modsRegexpString = '(?:\\s+(?:per|by)\\s+(platform|payment method))?'

usedModel = (group) ->
  switch group
    when 'platform'
      require('./lib/buyer/compared_by_platform')
    when 'payment method'
      require('./lib/buyer/compared_by_payment_method')
    else
      require('./lib/buyer/compared')

sendOutput = (msg, output) ->
  if Array.isArray(output)
    output.forEach (string) -> msg.send(string)
  else
    msg.send(output)

module.exports = (robot) ->

  # bhi / bmi / bbi
  robot.hear new RegExp(
    '^(?:b(h|m|b)i|buyer\\s+(hari|minggu|bulan)\\s+ini)' +
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

  # bhi vs tanggal
  robot.hear new RegExp(
    '^(?:bhi|buyer\\s+hari\\s+ini)\\s+vs\\s+(' +
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

  # buyer tanggal vs tanggal
  robot.hear new RegExp(
    '^buyer\\s+(?:tanggal\\s+)?(' +
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

  # buyer Xd
  robot.hear new RegExp(
    '^buyer\\s+(\\d+)d' +
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

  # buyer tanggal sd tanggal
  robot.hear new RegExp(
    '^buyer\\s+(?:tanggal\\s+)?(' +
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
      if err then return msg.send(err)
      sendOutput(msg, result.toString(reportPrefix))
