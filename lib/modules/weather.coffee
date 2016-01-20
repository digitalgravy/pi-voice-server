Promise = require("promise")
Module = require("../module")
http = require("http")
natural = require("natural")

verbInflector = new natural.PresentVerbInflector()

class WeatherModule extends Module
  apiKey = "0d83112f79ba6935a1c852fd37e0eb52"

  constructor: (@socket) ->
    console.log ">>> WeatherModule"

  parseTemperature: (temp) ->
    temp = Math.round(temp)
    response = ""
    condition = 0
    if temp < 0
      response = "extremely cold, below freezing"
      condition = 0
    else if temp < 3
      response = "very cold, near freezing"
      condition = 0
    else if temp < 5
      response = "quite cold, around #{temp} degrees"
      condition = 1
    else if temp < 10
      response = "cold, around #{temp} degrees"
      condition = 2
    else if temp < 15
      response = "cool, around #{temp} degrees"
      condition = 3
    else if temp < 20
      response = "moderate, around #{temp} degrees"
      condition = 4
    else if temp < 25
      response = "warm, around #{temp} degrees"
      condition = 5
    else if temp < 30
      response = "hot, around #{temp} degrees"
      condition = 6
    else
      response = "very hot, above 30 degrees"
      condition = 6
    {
      response: response
      condition: condition
    }

  parseRain: (rain, snow) ->
    response = ""
    if rain
      if rain["3hr"] < 0.2
        response = "might rain"
      else if rain["3hr"] < 0.5
        response = "is likely to rain"
      else if rain["3hr"] < 1
        response = "will probably rain"
      else
        response = "will rain"
    response

  runClientSide: =>
    new Promise (resolve, reject) =>
      # set up transcript
      transcript = "Currently the weather is "
      # get location
      http.get("http://ipinfo.io", (res) =>
        body = ""
        res.on("data", (chunk) ->
          body += chunk
        )
        res.on("end", =>
          res = JSON.parse(body)
          location = res.loc.split(",")
          # get the forcast
          http.get("http://api.openweathermap.org/data/2.5/forecast?lat=#{location[0]}&lon=#{location[1]}&units=metric&appid=#{apiKey}", (res) =>
            body = ""
            res.on("data", (chunk) ->
              body += chunk
            )
            res.on("end", =>
              res = JSON.parse(body)
              # upcoming is in list
              list = res.list
              # get now
              now = list[0]
              nowTemp = @parseTemperature(now.main.temp)
              # add current temp to transcript
              transcript += nowTemp.response
              isRaining = now.weather.main is "Rain"
              if isRaining
                transcript += " and it is raining"
              # get soon
              soon = list[1]
              soonTemp = @parseTemperature(soon.main.temp)
              soonRain = @parseRain(soon.rain)
              if soonRain isnt "" and isRaining is false
                transcript += " and it #{soonRain} soon"
              # get later
              later = list[2]
              laterTemp = @parseTemperature(later.main.temp)
              laterRain = @parseRain(soon.rain)
              # check to see if it changes
              laterPostfx = false
              if Math.abs(now.main.temp - later.main.temp) > 2.5
                warmerColder = if now.main.temp - later.main.temp > 0 then "colder" else "warmer"
                transcript += ", but will become #{warmerColder}, around #{Math.round(later.main.temp)} degrees later"
                laterPostfx = true
              if laterRain isnt soonRain
                if laterRain is ""
                  transcript += " and doesn't look like it will rain #{if laterPostfx is false then "later"}"
                else
                  transcript += " and it #{laterRain} #{if laterPostfx is false then "later"}"
              transcript += "."
              console.log new Date().toString(), "WeatherModule ::> runClientSide > transcript: '#{transcript}'"
              @socket.emit("speech", speak: transcript)
              resolve()
            )
          )
        )
      )

module.exports = WeatherModule
