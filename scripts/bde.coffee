# Description:
#   GMV queries
#
# Commands:
#   bde - tampilkan hari dengan GMV terbesar.
#   bde nh - tampilkan hari selain harbolnas dengan GMV terbesar.
#   bde (sunday|monday|etc) - tampiilkan hari dalam seminggu dengan GMV terbesar.

dateUtil = require('./lib/date_util')
outputFormatter = require('./lib/output_formatter/bde')
pg = require('./lib/pg')
moment = require('moment')

bdeQueryString = ->
  "
    select date, gmv, trx
    from (select date, sum(gmv) as gmv, sum(trx) as trx 
    from all_trx_daily where date>='2015-12-11 17:00:00' group by date) d
    order by gmv desc limit 1
  "

bdeExcludeDatesQueryString = (dates) ->
  datesString = dates.map (date) ->
    "'#{date.format('YYYY-MM-DD')}'"
  .join(',')
  "
    select date, gmv, trx
    from (select date, sum(gmv) as gmv, sum(trx) as trx 
    from all_trx_daily where date>='2015-12-11 17:00:00'
    and date not in (#{datesString}) group by date) d
    order by gmv desc limit 1
  "

bdeIncludeDatesQueryString = (dates) ->
  datesString = dates.map (date) ->
    "'#{date.format('YYYY-MM-DD')}'"
  .join(',')
  "
    select date, gmv, trx
    from (select date, sum(gmv) as gmv, sum(trx) as trx 
    from all_trx_daily where date>='2015-12-11 17:00:00'
    and date in (#{datesString}) group by date) d
    order by gmv desc limit 1
  "

harbolnasDates = ->
  dates = []
  now = dateUtil.now()
  harbolnasDate = dateUtil.parseDate('12-12-2010')
  while harbolnasDate.isBefore(now)
    dates.push moment(harbolnasDate)
    if harbolnasDate.date() is 14
      harbolnasDate.add(1, 'year')
      harbolnasDate.date(12)
    else
      harbolnasDate.add(1, 'day')
  dates

dayOfWeekDates = (dayOfWeekString)->
  dayOfWeek =
    switch dayOfWeekString.toLowerCase()
      when 'sunday', 'sun'
        7
      when 'monday', 'mon'
        1
      when 'tuesday', 'tue'
        2
      when 'wednesday', 'wed'
        3
      when 'thursday', 'thu'
        4
      when 'friday', 'fri'
        5
      when 'saturday', 'sat'
        6
  now = dateUtil.now()
  dates = []
  date = dateUtil.parseDate('01-01-2010').day(dayOfWeek)
  while date.isBefore(now)
    dates.push moment(date)
    date.add(7, 'day')
  dates

# TODO: use more accurate data.
module.exports = (robot) ->
  robot.hear /^bde$/i, (msg) ->
    pg.query bdeQueryString(), (err, result) ->
      if err then return msg.send(outputFormatter.dbError())
      rows = result.rows
      date = moment(rows[0].date, 'YYYY-MM-DD')
      msg.send(outputFormatter.bde(date, rows[0].trx, rows[0].gmv))

  robot.hear /^bde\s+nh$/i, (msg) ->
    pg.query bdeExcludeDatesQueryString(harbolnasDates()), (err, result) ->
      if err then return msg.send(outputFormatter.dbError())
      rows = result.rows
      date = moment(rows[0].date, 'YYYY-MM-DD')
      msg.send(outputFormatter.bde(date, rows[0].trx, rows[0].gmv, 'Best non-Harbolnas day'))

  robot.hear /^bde\s+(mon(?:day)?|tue(?:sday)?|wed(?:nesday)?|thu(?:rsday)?|fri(?:day)?|sat(?:urday)?|sun(?:day)?)$/i, (msg) ->
    pg.query bdeIncludeDatesQueryString(dayOfWeekDates(msg.match[1])), (err, result) ->
      if err then return msg.send(outputFormatter.dbError())
      rows = result.rows
      date = moment(rows[0].date, 'YYYY-MM-DD')
      msg.send(outputFormatter.bde(date, rows[0].trx, rows[0].gmv, "Best #{msg.match[1]}"))
