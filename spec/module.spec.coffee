Module = require "../lib/module"

describe "(Class) Module", ->

  beforeEach ->
    @module = new Module("{socket}")

  afterEach ->
    @module = undefined

  describe "(Property) socket", ->
    it "should expose a `socket` property", ->
      expect(@module.socket).toBe("{socket}")

  describe "(Method) runCommands", ->
    it "should expose a `runCommands` method", ->
      expect(@module.runCommands).toEqual(jasmine.any Function)
    it "should run `@runServerSide` and `@runClientSide`", ->
      spyOn(@module, "runServerSide").and.callThrough()
      spyOn(@module, "runClientSide").and.callThrough()
      @module.runCommands()
      expect(@module.runServerSide).toHaveBeenCalled()
      expect(@module.runClientSide).toHaveBeenCalled()

  describe "(Method) runServerSide", ->
    it "should expose a `runServerSide` method", ->
      expect(@module.runServerSide).toEqual(jasmine.any Function)
    it "should return a Promise", ->
      expect(@module.runServerSide().then).toEqual(jasmine.any Function)

  describe "(Method) runClientSide", ->
    it "should expose a `runClientSide` method", ->
      expect(@module.runClientSide).toEqual(jasmine.any Function)
    it "should return a Promise", ->
      expect(@module.runClientSide().then).toEqual(jasmine.any Function)
