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
#   hubot was <ist|war> am <day> los - Show nadann events for the given date (the 'am' is optional). <day> - heute|morgen|gestern|Montag|..|Sonntag
#
# Author:
#   djmaze
cheerio = require 'cheerio'
later = require 'later'
moment = require 'moment'

class NadannEventFetcher
  constructor: (@robot) ->

  getEventsFor: (date, cb) ->
    @robot.http(@getUrlFor(date))
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

  getUrlFor: (date) ->
    "http://www.nadann.de/Veranstaltungskalender/Tag/#{@dayNumberFor date}"

  dayNumberFor: (date) ->
    if date.getDay() < 3 then date.getDay() + 4 else date.getDay() - 3

getDateFor = (dateWord) ->
  today = new Date()
  switch dateWord
    when 'heute', '' then new Date()
    when 'morgen' then new Date(today.valueOf() + 1000*60*60*24)
    when 'gestern' then new Date(today.valueOf() - 1000*60*60*24)
    else
      englishDateWord = dateWord.replace(/montag/i, 'monday').replace(/dienstag/i, 'tuesday').replace(/mittwoch/i, 'wednesday').replace(/donnerstag/i, 'thursday').replace(/freitag/i, 'friday').replace(/samstag/i, 'saturday').replace(/sonntag/i, 'sunday')
      later.schedule(later.parse.text('on ' + englishDateWord)).next()

locationWhitelisted = (name) ->
  name.match /\b(sputnikhalle|sputnikcafe|(plan b)|(hot jazz club)|SpecOps|Metro|jovel|baracke|lwl-museum|(rote lola)|AMP|Triptychon|(Cuba Nova))\b/i

module.exports = (robot) ->
  robot.respond /was (ist|war) (am )?(\w+) los/i, (msg) ->
    date = getDateFor msg.match[3]
    dateString = moment(date).locale('de').format('LLLL').replace /\s\d+:\d+$/, ''
    eventFetcher = new NadannEventFetcher robot

    eventFetcher.getEventsFor date, (events) ->
      msg.send "Events am #{dateString}:\n" + events.filter (event) ->
        locationWhitelisted event.location
      .map (event) ->
        "- #{event.text} (#{event.location}, #{event.time} Uhr)"
      .join("\n") +
      "\n\n(Quelle: #{eventFetcher.getUrlFor date})"
