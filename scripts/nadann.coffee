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
        for $event in $('.card-columns-events .card-text')
          time_text = $('strong:first-child', $event).text().trim()
          complete_text = $($event).text().replace(/\s+/g, ' ')
          events.push
            time: time_text
            title: $('strong:nth-child(2)', $event).text().trim()
            location: $('em', $event).text().trim()
            text: complete_text
        sorted = events.sort (a,b) ->
          if(a.time >= b.time) then 1 else -1
        cb sorted

  getUrlFor: (date) ->
    "https://www.nadann.de/rubriken/veranstaltungen/#{@dayNumberFor date}/"

  dayNumberFor: (date) ->
    switch date.getDay()
      # FIXME What about the second wednesday?
      when 0 then 'sonntag'
      when 1 then 'montag'
      when 2 then 'dienstag'
      when 3 then 'mittwoch-i'
      when 4 then 'donnerstag'
      when 5 then 'freitag'
      when 6 then 'samstag'

class BlacklistedLocations
  constructor: (@robot) ->

  includes: (name) ->
    for location in @locations()
      console.log "#{name}.match /#{location}/i"
      return true if name.match ///#{location}///i
    return false

  add: (location) ->
    @locations().push location if location not in @locations()

  clear: ->
    @robot.brain.data['nadann_blacklisted_locations'] = []

  locations: ->
    @robot.brain.data['nadann_blacklisted_locations'] ||= []

getDateFor = (dateWord) ->
  today = new Date()
  switch dateWord
    when 'heute', '' then new Date()
    when 'morgen' then new Date(today.valueOf() + 1000*60*60*24)
    when 'gestern' then new Date(today.valueOf() - 1000*60*60*24)
    else
      englishDateWord = dateWord.replace(/montag/i, 'monday').replace(/dienstag/i, 'tuesday').replace(/mittwoch/i, 'wednesday').replace(/donnerstag/i, 'thursday').replace(/freitag/i, 'friday').replace(/samstag/i, 'saturday').replace(/sonntag/i, 'sunday')
      later.schedule(later.parse.text('on ' + englishDateWord)).next()

module.exports = (robot) ->
  blacklistedLocations = new BlacklistedLocations(robot)

  showblacklistedLocations = (msg) ->
    msg.send "Aktuell verborgene Event-Locations:\n" + blacklistedLocations.locations().join("\n")

  robot.respond /was (ist|war) (am )?(\w+) los/i, (msg) ->
    date = getDateFor msg.match[3]
    dateString = moment(date).locale('de').format('LLLL').replace /\s\d+:\d+$/, ''
    eventFetcher = new NadannEventFetcher robot

    eventFetcher.getEventsFor date, (events) ->
      msg.send "Events am #{dateString}:\n" + events.filter (event) ->
        !blacklistedLocations.includes(event.location)
      .map (event) ->
        "- #{event.text}"
      .join("\n") +
      "\n\n(Quelle: #{eventFetcher.getUrlFor date})"

  robot.respond /verberge events für (.+)/i, (msg) ->
    location = msg.match[1]
    msg.send "Okay, verberge #{location}."
    blacklistedLocations.add location

  robot.respond /zeige events für (.+)/i, (msg) ->
    location = msg.match[1]
    msg.send "Okay, zeige #{location}."
    blacklistedLocations.add location

  robot.respond /verberge keine locations mehr/i, (msg) ->
    blacklistedLocations.clear()
    msg.send "Okay, keine Event-Locations werden mehr verborgen."

  robot.respond /welche locations sind aktuell verborgen/i, (msg) ->
    showblacklistedLocations msg
