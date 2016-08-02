# Description:
#   Search images through the Searx metasearch API.
#
# Configuration
#   HUBOT_SEARX_URL - The URL of the Searx instance to use.
#   HUBOT_SEARX_LANGUAGE - Optional. Search language to use, e.g. "de_DE".
#
# Commands:
#   hubot image me <query> - Queries Searx images for <query> and returns a random top result.
module.exports = (robot) ->
  robot.respond /(image|img)( me)? (.+)/i, (msg) ->
    imageMe msg, msg.match[3], (url) ->
      msg.send url

imageMe = (msg, query, cb) ->
  searxUrl = process.env.HUBOT_SEARX_URL
  language = process.env.HUBOT_SEARX_LANGUAGE

  if searxUrl
    q =
      q: query
      format: 'json'
      categories: 'images'
    cookies = "language=#{language}" if language

    msg.http(searxUrl, rejectUnauthorized: false)
      .header('Cookie', cookies)
      .query(q)
      .get() (err, res, body) ->
        if err
          msg.send "Error during query: #{err}"
          msg.send "Error during query. #{res.statusCode}"
        else
          msg.robot.logger.debug body
          response = JSON.parse(body)
          if response?.results
            image = msg.random response.results
            cb image.img_src
  else
    msg.send "Please supply HUBOT_SEARX_URL."
