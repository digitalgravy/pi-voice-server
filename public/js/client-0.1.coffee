root = exports ? this

# Organise globals
SpeechRecognition = this.SpeechRecognition or this.webkitSpeechRecognition
SpeechGrammar = this.SpeechGrammar or this.webkitSpeechGrammar
SpeechGrammarList = this.SpeechGrammarList or this.webkitSpeechGrammarList
SpeechSynthesisUtterance = this.SpeechSynthesisUtterance or this.webkitSpeechSynthesisUtterance
speechSynthesis = this.speechSynthesis or this.webkitSpeechSynthesis
requestAnimationFrame = this.requestAnimationFrame or this.webkitRequestAnimationFrame

# Organise client
class VoiceClient
  listening = false
  allowedToListen = false
  listeningBeep = new Audio("/sounds/listening_dbl.wav")
  finishedListeningBeep = new Audio("/sounds/listened.wav")
  listeningTimeout = null
  displayTimeout = null

  constructor: (opts) ->
    @socket = opts.socket
    @debugElem = opts.debug or $('<p>')
    @outputElem = opts.output or $('<div>')
    @confidenceElem = opts.confidence or $('<div>')
    @givenName = opts.givenName
    @givenNameRegExp = new RegExp(this.givenName, 'i')
    @listeningDelay = opts.listeningDelay or 5000
    stopListeningCommand = opts.stopListening or "stop listening"
    @stopListeningCommand = new RegExp(stopListeningCommand, 'i')
    startListeningCommand = opts.startListening or "continue listening"
    @startListeningCommand = new RegExp(startListeningCommand, 'i')
    allowedToListen = opts.listeningByDefault or true
    if allowedToListen then @allowListening() else @disallowListening()

    if opts.waveform
      @waveform = new WaveformClient(canvas: opts.waveform)

    @initSpeech()
    @initSocket()

  initSocket: ->
    @socket.on("response", (data) =>
      if data.error is null and data.label
        console.log "found match: '#{data.label}' with a #{data.certainty} certainty"
    )
    @socket.on("speech", (data) =>
      console.log "Speaking... '#{data.speak}'"
      @speak(data.speak)
    )

  initSpeech: ->
    # Initialise recognition
    @recognition = new SpeechRecognition()
    @recognition.lang = "en"
    @recognition.continuous = true
    @recognition.interimResults = true

    # Initialise name recognition
    givenNameGrammar = new SpeechGrammar()
    givenNameGrammar.src = "#JSGF V1.0; grammar names; public <name> = #{@givenName};"
    givenNameGrammarList = new SpeechGrammarList()
    givenNameGrammarList.addFromString(givenNameGrammar, 1)
    @recognition.grammars = givenNameGrammarList

    # Listen to events
    @recognition.addEventListener("result", (evt) => @parseSpeech(evt) )
    @recognition.addEventListener("end", => @listenForSpeech() )
    @recognition.addEventListener("start", -> console.log "Parsing speech..." )
    @timeStartedListening = null

    # Listen for speech
    @listenForSpeech()

  speak: (text) ->
    @cancelListening()
    utterance = new SpeechSynthesisUtterance(text)
    utterance.lang = "en-GB"
    speechName = "Google UK English Female"
    voices = speechSynthesis.getVoices()
    utterance.voice = voices.filter( (voice) -> return voice.name is speechName)[0]
    utterance.onend = (event) =>
      console.log "Finished speaking."
      @listenForSpeech()
    speechSynthesis.speak(utterance)

  parseSpeech: (event) ->
    requestAnimationFrame =>
      result = event.results[event.resultIndex]
      item = result[0]
      # console.log "transcript: #{item.transcript}"
      transcript = item.transcript.replace(/^\s+|\s+$/g, "")
      
      if @givenNameRegExp.test(transcript) and listening is false
        @startListening()

      if allowedToListen is true
        @debugElem.text(transcript.replace(@givenNameRegExp, "").replace(/^\s+|\s+$/g, "")).css(
          opacity: if result.isFinal then 1 else 0.7
          color: if listening then "#fff" else "#f00"
        )
        if result.isFinal
          if displayTimeout then clearTimeout(displayTimeout)
          @debugElem.stop()
          displayTimeout = setTimeout( =>
            @debugElem.animate({opacity:0}, 1000, ->
              $(this).text("")
            )
          , 5000)

      if result.isFinal is true and listening is true
        transcript = transcript.replace(@givenNameRegExp, "").replace(/^\s+|\s+$/g, "")
        if allowedToListen is false and @startListeningCommand.test(transcript)
          @allowListening()
        else if allowedToListen is true and @stopListeningCommand.test(transcript)
          @disallowListening()
        else if transcript isnt "" and allowedToListen is true
          @stopListening()
          console.log "Got transcript: '#{transcript}'"
          #@outputElem.text(transcript)
          @socket.emit("speech", transcript: transcript)
          @timeStartedListening = null
          console.log "Stopped parsing speech..."

      if result.isFinal is true
        @restartService()

  restartService: ->
    @cancelListening()
    @listenForSpeech()

  cancelListening: ->
    console.log "Stopping recognition."
    @recognition.stop()

  abortListening: ->
    try
      @recognition.abort()
      console.log "Aborting recognition."

  startListening: ->
    listening = true
    if allowedToListen is true
      $("body").addClass("loading")
      console.log "listening..."
      listeningBeep.play(0)
      if @waveform then @waveform.show()
    # listen timeout
    if listeningTimeout then clearTimeout(listeningTimeout)
    listeningTimeout = setTimeout =>
      @stopListening()
    , @listeningDelay
    
  stopListening: (notify = true) ->
    $("body").removeClass("loading")
    if listeningTimeout then clearTimeout(listeningTimeout)
    listening = false
    if allowedToListen is true
      console.log "finished listening."
      if @waveform then @waveform.hide()
      if notify is true then finishedListeningBeep.play(0)

  allowListening: ->
    @stopListening(false)
    $("body").removeClass("listening_disabled")
    console.log "Now listening for commands."
    allowedToListen = true
    listeningBeep.play(0)

  disallowListening: ->
    @stopListening()
    $("body").addClass("listening_disabled")
    console.log "No longer listening for commands."
    allowedToListen = false
    finishedListeningBeep.play(0)

  listenForSpeech: ->
    try
      console.log "Trying to start recognition..."
      @recognition.start()
      console.log "Starting recognition."
    catch e
      #console.log e

root.VoiceClient = VoiceClient