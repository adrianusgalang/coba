queryUtil = require '../query_util'
moment = require 'moment'

class Gmv
  query = "
    SELECT
      SUM(pt.amount) + SUM(courier_cost) as gmv
    FROM
      virtual_product_agents va
    JOIN
      payment_transactions pt ON va.user_id = pt.buyer_id
    LEFT JOIN
      virtual_product_agents va2 ON va.referrer_id = va2.id
    LEFT JOIN
      users u2 ON va2.user_id = u2.id
    WHERE
      va.deleted = 0
    AND pt.courier = 'Wholesale'
    AND pt.fake = 0
    AND pt.seller_id IN (57642764,60835114)
    AND pt.paid_at IS NOT NULL
    AND paid_at >= ?
    AND paid_at < ?"

  constructor: (queryStart, queryEnd) ->
    @queryStart = moment(queryStart)
    @queryEnd = moment(queryEnd)

  load: (cb) ->
    queryUtil.batchQuery query, @queryStart, @queryEnd, (err, results) ->
      if err then return cb(err, null)
      reduceFunc = (total, rows) -> total + rows[0].gmv
      cb(null, results.reduce(reduceFunc, 0))

module.exports = Gmv
