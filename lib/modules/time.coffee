Promise = require("promise")
Module = require("../module")
Moment = require("moment")

class TimeModule extends Module
  constructor: (@socket) ->
    console.log ">>> TimeModule"

  fuzzyTime: ->
    minutes = Moment().minutes()
    minuteName = ""
    minutePostfix = "past"
    hourPostfix = ""
    hour = Moment()
    if minutes > 33
      minutes = 60 - minutes
      minutePostfix = "to"
      hour.add(h:1)
    if minutes < 4
      minuteName = ""
      minutePostfix = ""
      hourPostfix = "o'clock"
    else if minutes < 8
      minuteName = "5 minutes"
    else if minutes < 13
      minuteName = "10"
    else if minutes < 18
      minuteName = "quarter"
    else if minutes < 23
      minuteName = "20"
    else if minutes < 27
      minuteName = "25 minutes"
    else
      minuteName = "half"
    text = "It is #{minuteName} #{minutePostfix} #{hour.format("h")} #{hourPostfix}"

  runClientSide: =>
    new Promise (resolve, reject) =>
      hour = Moment().format("h")
      if hour is "0"
        hour = 12
      minute = Moment().format("mm")
      if minute is "00"
        minute = "o'clock"
      else
        minute += ", #{Moment().format("a")}"
      currentTime = "The time is #{hour}, #{minute}, on #{Moment().format("dddd, MMMM Do")}"
      currentTime = @fuzzyTime()
      console.log new Date().toString(), "TimeModule ::> runClientSide > Execute socket with '#{currentTime}'"
      @socket.emit("speech", speak: currentTime)
      resolve()

module.exports = TimeModule