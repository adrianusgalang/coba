# Description:
#   Revenue queries
#
# Commands:
#   revenue hari ini / rhi - lihat revenue hari ini
#   revenue minggu ini / rmi - lihat revenue minggu ini (mulai hari jumat)
#   revenue bulan ini / rbi - lihat revenue bulan ini
#   revenue <t1> - lihat revenue dari tanggal <t1> hingga sekarang. format tanggal DD-MM-YYYY / Xdago
#   revenue <t1> sd <t2> - lihat revenue dari tanggal <t1> hingga <t2>. format tanggal DD-MM-YYYY / Xdago
#   revenue <t1> vs <t2> - bandingkan revenue tanggal <t1> dan <t2>. format tanggal DD-MM-YYYY / Xdago
#   revenue <X>d - lihat revenue <X> hari terakhir serta <X> hari sebelumnya
#   revenue hari ini vs <t> / rhi vs <t> - bandingkan revenue hari ini dan tanggal <t>. format tanggal DD-MM-YYYY / Xdago
#   <revenue_command> per platform - tampilkan informasi revenue per platform
#   <revenue_command> per source - tampilkan informasi revenue per source
# Author:
#   ardfard

dateUtil = require('./lib/date_util')
moment = require('moment')

modsRegexpString = '(?:\\s+(?:per|by)\\s+(platform|source))?'

usedModel = (group) ->
  switch group
    when 'platform'
      require('./lib/revenue/compared_by_platform')
    when 'source'
      require('./lib/revenue/compared_by_source')
    else
      require('./lib/revenue/compared')

sendOutput = (msg, output) ->
  if Array.isArray(output)
    output.forEach (string) -> msg.send(string)
  else
    msg.send(output)

module.exports = (robot) ->

  # rhi / rmi / rbi
  robot.hear new RegExp(
    '^(?:r(h|m|b)i|revenue\\s+(hari|minggu|bulan)\\s+ini)' +
    modsRegexpString + '$'
    , 'im'
  ), (msg) ->
    Model = usedModel(msg.match[3])
    #console.log(msg.match[1])
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
    #msg.send("masuk rhi rmi rbi #{msg.match[1]} #{msg.match[2]} #{msg.match[3]}")
    #console.log("mau masuk revenue")
    model.load (err, result) ->
      if err then return msg.send(err)
      sendOutput(msg, result.toString(reportCurrentPrefix, reportLastPrefix))

  # rhi vs tanggal
  robot.hear new RegExp(
    '^(?:rhi|revenue\\s+hari\\s+ini)\\s+vs\\s+(' +
    dateUtil.dateRegexp().source +
    ')' + modsRegexpString + '$'
    , 'im'
  ), (msg) ->
    Model = usedModel(msg.match[3])

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

  # revenue tanggal vs tanggal
  robot.hear new RegExp(
    '^revenue\\s+(?:tanggal\\s+)?(' +
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

  # revenue Xd
  robot.hear new RegExp(
    '^revenue\\s+(\\d+)d' +
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

  # revenue tanggal sd tanggal
  robot.hear new RegExp(
    '^revenue\\s+(?:tanggal\\s+)?(' +
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
