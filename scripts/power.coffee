http = require('http')

sockets =
  'Monitor': 2
  'Licht': 3
  'Anlage': 4

findSocket = (term) ->
  termId = parseInt term
  for name, id of sockets
    return [name, id] if id == termId or name.toLowerCase() == term.toLowerCase()
  [null, null]

switchPower = (id, enable) ->
  on_or_off = if enable then 'on' else 'off'
  new Promise (resolve, reject) ->
    req = http.request
      hostname: process.env.SIS_PM_WEB_HOST
      port: 2638
      path: "/switch/#{id}/#{on_or_off}"
      method: 'PUT'
    , (response) ->
      resolve()

    req.setTimeout 10*1000
    req.on 'error', (error) ->
      console.log 'error during request: ', error
      reject error.message
    req.end()

module.exports = (robot) ->
  brainData = ->
      robot.brain.data['power'] ||= {}

  fromAdmin = (msg) ->
    switch robot.adapterName
      when 'xmpp'
        adminRegexp = new RegExp('^' + process.env.HUBOT_XMPP_ADMIN_JID + '/')
        jid = msg.envelope.user.privateChatJID
        jid.match adminRegexp if jid
      when 'matrix'
        msg.envelope.user.id == process.env.HUBOT_MATRIX_ADMIN_ID
      else
        raise 'Unknown adapter'

  robot.respond /(erlaube|verbiete) strom/i, (msg) ->
    unless fromAdmin(msg)
      msg.reply 'Nee, das darf nur der Papa!'
      return

    enable = (msg.match[1].toLowerCase() == 'erlaube')
    brainData()['allow'] = enable
    msg.reply if enable then 'Ok, Strom-Zugang freigeschaltet' else 'Ok, Strom-Zugang gesperrt'

  robot.respond /(\w+) (an|aus|on|off)/i, (msg) ->
      unless brainData()['allow'] or fromAdmin(msg)
        msg.reply 'Nee, aktuell nicht erlaubt!'
        return

      [name, id] = findSocket msg.match[1]
      enable = (msg.match[2].match /an|on/)
      if id
        switchPower(id, enable).then ->
          an_or_aus = if enable then 'an' else 'aus'
          msg.send "#{name} #{an_or_aus}geschaltet"
        , (error) ->
          msg.send "Fehler beim Umschalten von #{name}: #{error}"
      else
        msg.send "#{msg.match[1]} gibts nicht!"
