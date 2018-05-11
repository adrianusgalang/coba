numeral = require 'numeral'

class Numbers
  constructor: ->
    numeral.language 'id',
      delimiters:
        thousands: '.'
        decimal: ','
      abbreviations:
        thousand: 'rb'
        million: 'jt'
        billion: 'm'
        trillion: 't'
      currency:
        symbol: 'Rp'
    numeral.language('id')

    Number.prototype.toRp = ->
      return 'NaN' unless isFinite(this)
      numeral(this).format('$0,0')

    Number.prototype.toPercent = ->
      return 'NaN' unless isFinite(this)
      numeral(this).format('0.000%')

    Number.prototype.toNum = ->
      return 'NaN' unless isFinite(this)
      numeral(this).format('0,0')

module.exports = new Numbers
