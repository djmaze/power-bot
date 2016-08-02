# Description:
#   Search images through the Searx metasearch API.
#
# Configuration
#   HUBOT_SEARX_URL - The URL of the Searx instance to use.
#   HUBOT_SEARX_LANGUAGE - Optional. Search language to use, e.g. "de_DE".
#
# Commands:
#   hubot image me <query> - Queries Searx images for <query> and returns a random top result image url.
#   hubot music me <query> - Queries Searx music for <query> and returns the top result track url.
#   hubot map me <query> - Queries Searx maps for <query> and returns the top result map url.
module.exports = (robot) ->
  robot.respond /(image|img)( me)? (.+)/i, (msg) ->
    imageMe msg, msg.match[3], (url) ->
      msg.send url

  robot.respond /(music)( me)? (.+)/i, (msg) ->
    musicMe msg, msg.match[3], (url) ->
      msg.send url

  robot.respond /(map)( me)? (.+)/i, (msg) ->
    mapMe msg, msg.match[3], (url) ->
      msg.send url

imageMe = (msg, query, cb) ->
  querySearx msg, query, 'images', null, (results) ->
    image = msg.random results
    cb image.img_src

musicMe = (msg, query, cb) ->
  querySearx msg, query, 'music', null, (results) ->
    track = results[0]
    cb "#{track.title}: #{track.pretty_url}"

mapMe = (msg, query, cb) ->
  querySearx msg, query, 'map', null, (results) ->
    place = results[0]
    cb "#{place.title}: #{place.pretty_url}"

querySearx = (msg, query, categories, engines, cb) ->
  searxUrl = process.env.HUBOT_SEARX_URL
  language = process.env.HUBOT_SEARX_LANGUAGE

  if searxUrl
    q =
      q: query
      format: 'json'
      categories: categories
      engines: engines
    cookies = "language=#{language}" if language

    msg.http(searxUrl, rejectUnauthorized: false)
      .header('Cookie', cookies)
      .query(q)
      .get() (err, res, body) ->
        if err
          msg.send "Error during query: #{err}"
          msg.send "Error during query. #{res.statusCode}"
        else
          response = JSON.parse(body)
          if response?.results
            if response.results.length > 0
              cb response.results
            else
              msg.send "No results for \"#{query}\"."
  else
    msg.send "Please supply HUBOT_SEARX_URL."
