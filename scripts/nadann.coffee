# Description:
#   Hubot script to get events for a specific day from the nadann site
#
# Dependencies:
#   cheerio (from NPM)
#
# Configuration:
#   None
#
# Commands:
#   hubot was (ist|war) (heute|morgen|gestern) los - Show nadann events for the given date
#
# Author:
#   djmaze
cheerio = require 'cheerio'

class NadannEventFetcher
  constructor: (@robot) ->

  getFor: (date, cb) ->
    @robot.http("http://www.nadann.de/Veranstaltungskalender/Tag/#{@dayNumberFor date}")
      .get() (err, res, body) ->
        $ = cheerio.load body
        events = []
        for $event in $('.event')
          date_text = $('.event-date', $event).text().trim()
          events.push
            date: date_text
            time: date_text.match(/(\d+:\d+)/)[0]
            location: $('.event-location', $event).text().trim()
            text: $('.event-text', $event).text().trim()
        cb events

  dayNumberFor: (date) ->
    if date.getDay() < 3 then date.getDay() + 4 else date.getDay() - 3

getDateFor = (date_word) ->
  today = new Date()
  switch date_word
    when 'heute', '' then new Date()
    when 'morgen' then new Date(today.valueOf() + 1000*60*60*24)
    when 'gestern' then new Date(today.valueOf() - 1000*60*60*24)

module.exports = (robot) ->
  robot.respond /was (ist|war) (.+) los/i, (msg) ->
    date = getDateFor msg.match[2]

    new NadannEventFetcher(robot).getFor date, (events) ->
      msg.send events.filter (event) ->
        event.location.match /\b(sputnikhalle|(plan b)|(hot jazz club)|SpecOps|Metro|jovel|baracke|lwl-museum|(rote lola)|AMP|Triptychon|(Cuba Nova))\b/i
      .map (event) ->
        "- #{event.text} (#{event.location}, #{event.time} Uhr)"
      .join("\n")
