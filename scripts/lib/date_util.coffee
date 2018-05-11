moment = require 'moment'

class DateUtil
  absDateRegexp = /\d?\d-\d?\d-20\d\d/
  relDateRegexp = /\d+dago/im

  now: ->
    moment().utcOffset(7)

  today: ->
    @now().startOf('day')

  dateRegexp: ->
    new RegExp(absDateRegexp.source + '|' + relDateRegexp.source, 'im')

  parseDate: (dateString) ->
    if new RegExp('^' + absDateRegexp.source + '$', 'im').test(dateString)
      d = moment(dateString, 'DD-MM-YYYY')
      if d.isValid()
        d.utcOffset(7).startOf('day')
      else
        null
    else if new RegExp('^' + relDateRegexp.source + '$', 'im').test(dateString)
      days = /\d+/.exec(dateString)[0]
      @today().subtract(+days, 'days')
    else
      null

module.exports = new DateUtil
