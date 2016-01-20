Promise = require("promise")
Module = require("../module")

class HelloModule extends Module
  constructor: (@socket) ->
    console.log ">>> HelloModule"

  runClientSide: =>
    new Promise (resolve, reject) =>
      @socket.emit("speech", speak: "Hello digital people in Peterborough")
      resolve()

module.exports = HelloModule