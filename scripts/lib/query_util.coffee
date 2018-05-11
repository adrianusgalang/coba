mysql = require './mysql'
moment = require 'moment'
async = require 'async'

class QueryUtil
  caeID: '(21985064,16595749,21985064,9341368)'

  query: (query, cb) ->
    query = query.replace(/\s+/g, ' ')
    mysql.getConnection (err, connection) ->
      if err then return cb(err, null)
      connection.query query, (err, rows, fields) ->
        connection.release()
        cb(err, rows, fields)

  batchQuery: (query, from, to, cb) ->
    query = query.replace(/\s+/g, ' ')
    from = moment(from)
    unless to then to = moment()
    to = moment(to)

    ranges = []
    interval = 1 # days
    while from.isBefore(to)
      f = moment(from)
      t = moment(from).add(interval, 'days')
      if to.isBefore(t) then t = moment(to)

      ranges.push([f.utc(), t.utc() ])
      from.add(interval, 'days')

    #console.log("#{ranges}")

    queries = ranges.map (range) ->
      (cb2) ->
        mysql.getConnection (err, connection) ->
          if err then return cb2(err, null)
          fromString = range[0].format('YYYY-MM-DD HH:mm:ss')
          toString = range[1].format('YYYY-MM-DD HH:mm:ss')
          connection.query query, [fromString, toString], (err, rows, fields) ->
            connection.release()
            cb2(err, { rows: rows, fields: fields })

    async.parallel queries, (err, results) ->
      if err then return cb(err, null, null)
      cb(null, results.map((result) -> result.rows), results[0].fields)

  paymentMethodsQuery = "
    select
      distinct payment_method
    from
      payment_transactions
    where
      payment_method not in ('', 'bca', 'true', 'xl_tunai')
      and payment_method is not null"
  getPaymentMethods: (cb) ->
    @query paymentMethodsQuery, (err, rows) ->
      if err then return cb(err, null)
      cb(null, rows.map (row) -> row.payment_method)

  platformsQuery = "
    select
      distinct created_on
    from
      payment_transactions
    where
      created_on is not null"
  getPlatforms: (cb) ->
    @query platformsQuery, (err, rows) ->
      if err then return cb(err, null)
      cb(null, rows.map (row) -> row.created_on)

module.exports = new QueryUtil
