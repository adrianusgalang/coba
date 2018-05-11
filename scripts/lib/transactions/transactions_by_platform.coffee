queryUtil = require '../query_util'
async = require 'async'
moment = require 'moment'

class TransactionsByPlatform
  query = "
    select
      created_on,
      count(*) as count
    from payment_transactions
    where
      created_at >= ?
      and created_at < ?
      and (buyer_type <> \'User\' or buyer_id not in (21985064,16595749,21985064,9341368))
      and agent_commission_amount <= 0
    group by
      created_on"
  otherQueryTemplate = (filter) ->
    "
      select
        count(*) as count
      from payment_transactions
      where
        created_at >= ?
        and created_at < ?
        #{filter or ''}
    "
  caeQuery = otherQueryTemplate('and buyer_type=\'User\' and buyer_id in (21985064,16595749,21985064,9341368)')
  o2oQuery = otherQueryTemplate('and agent_commission_amount > 0')

  loadOther = (otherQuery, queryStart, queryEnd, cb) ->
    queryUtil.batchQuery otherQuery, queryStart, queryEnd, (err, results) ->
      if err then return cb(err, null)
      reduceFunc = (total, rows) -> total + rows[0].count
      cb(null, results.reduce(reduceFunc, 0))

  loadByPlatform = (queryStart, queryEnd, cb) ->
    queryUtil.batchQuery query, queryStart, queryEnd, (err, results) ->
      if err then return cb(err, null)
      data = {}
      results.forEach (rows) ->
        rows.forEach (row) ->
          currentTotal = data[row.created_on] or 0
          data[row.created_on] = currentTotal + row.count
      cb(null, data)

  constructor: (queryStart, queryEnd) ->
    @queryStart = moment(queryStart)
    @queryEnd = moment(queryEnd)

  load: (cb) ->
    queries = [
      ((cb2) => loadByPlatform @queryStart, @queryEnd, (err, res) -> cb2(err, res))
      ((cb2) => loadOther caeQuery, @queryStart, @queryEnd, (err, res) -> cb2(err, res)),
      ((cb2) => loadOther o2oQuery, @queryStart, @queryEnd, (err, res) -> cb2(err, res))
    ]
    async.parallel queries, (err, results) ->
      if err then return cb(err, null)
      data = results[0]
      cae = results[1]
      o2o = results[2]
      if cae > 0
        data['cae'] = cae
      if o2o > 0
        data['o2o'] = o2o
      cb(null, data)

module.exports = TransactionsByPlatform
