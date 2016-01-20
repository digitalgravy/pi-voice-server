Promise = require("promise")

class Module
  constructor: (@socket) ->

  runCommands: ->
    @runServerSide().then(@runClientSide)

  runServerSide: ->
    new Promise (resolve, reject) ->
      resolve()

  runClientSide: ->
    new Promise (resolve, reject) ->
      resolve()

module.exports = Module