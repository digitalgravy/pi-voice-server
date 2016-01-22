###
  Large parts of this file are taken from the extrordinary work done by Chris Wilson (https://github.com/cwilso/PitchDetect/blob/master/js/pitchdetect.js):
  
  Copyright (c) 2014 Chris Wilson
  
  Permission is hereby granted, free of charge, to any person obtaining a copy
  of this software and associated documentation files (the "Software"), to deal
  in the Software without restriction, including without limitation the rights
  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
  copies of the Software, and to permit persons to whom the Software is
  furnished to do so, subject to the following conditions:
  The above copyright notice and this permission notice shall be included in all
  copies or substantial portions of the Software.
  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
  SOFTWARE.
###

root = exports ? this

# Organise globals
requestAnimationFrame = this.requestAnimationFrame or this.webkitRequestAnimationFrame
getUserMedia = (dictionary, callback, error) =>
  @navigator.getUserMedia = @navigator.getUserMedia or @navigator.webkitGetUserMedia
  @navigator.getUserMedia(dictionary, callback, error)

class PitchDetect
  buffer = new Float32Array(1024)
  mediaStreamSource = null
  analyser = null
  audioContext = null
  logs = []
  logging = false
  voiceGuess = []
  emptyCount = 0

  constructor: (opts) ->
    audioContext = new AudioContext()
    getUserMedia(
      audio:
        mandatory:
          googEchoCancellation: false
          googAutoGainControl: false
          googNoiseSuppression: false
          googHighpassFilter: false
        optional: []
    , (stream) =>
      mediaStreamSource = audioContext.createMediaStreamSource(stream)
      analyser = audioContext.createAnalyser()
      analyser.fftSize = 2048
      mediaStreamSource.connect(analyser)
      @update()
    , (ex) ->
      console.log "getUserMedia threw exception: #{ex}"
    )

  update: ->
    analyser.getFloatTimeDomainData(buffer)
    @ac = @autoCorrelate(buffer, audioContext.sampleRate)
    @displayPitch()
    @guessVoice()

  autoCorrelate: (buffer, sampleRate) ->
    SIZE = buffer.length
    MIN_SAMPLES = 0
    MAX_SAMPLES = Math.floor(SIZE/2)
    best_offset = -1
    best_correlation = 0
    rms = 0
    foundGoodCorrelation = false
    correlations = new Array(MAX_SAMPLES)
    for num in [0..SIZE-1]
      val = buffer[num]
      rms += val*val
    rms = Math.sqrt(rms/SIZE)
    if rms < 0.01
      return -1
    else
      lastCorrelation = 1
      for offset in [MIN_SAMPLES..MAX_SAMPLES]
        correlation = 0
        for num in [0..MAX_SAMPLES]
          correlation += Math.abs((buffer[num])-(buffer[num + offset]))
        correlation = 1 - (correlation/MAX_SAMPLES)
        correlations[offset] = correlation
        if correlation > 0.9 and correlation > lastCorrelation
          foundGoodCorrelation = true
          if correlation > best_correlation
            best_correlation = correlation
            best_offset = offset
        else if foundGoodCorrelation
          shift = (correlations[best_offset + 1] - correlations[best_offset - 1]) / correlations[best_offset]
          return sampleRate / (best_offset + (8 * shift))
        lastCorrelation = correlation
      if best_correlation > 0.01
        return sampleRate / best_offset
      return -1

  displayPitch: ->
    ac = if @ac is -1 then "--" else Math.round(@ac)
    console.log "Pitch: #{ac}Hz, guesses: #{voiceGuess.length}"
    requestAnimationFrame =>
      @update()
      if logging is true then @logPitch()

  guessVoice: ->
    start = 0
    end = window.HighPoint
    sampleSize = 100
    pauseLength = 50
    if @ac is -1
      emptyCount = emptyCount + 1
    else
      if emptyCount > pauseLength
        voiceGuess = []
      emptyCount = 0
      voiceGuess.push(@ac)
      if voiceGuess.length > sampleSize
        voiceGuess = voiceGuess.splice(voiceGuess.length - sampleSize)

      # work out mean
      avg = 0;
      count = 0;
      for val in voiceGuess
        if val > start and val < end
          avg += val
          count = count + 1
      avg = (avg / count).toFixed(1)
      document.getElementById("d3Mean").textContent = avg

      # work out which it probably is...
      maleVoiceMean = window.d1Mean
      maleDelta = Math.abs(maleVoiceMean - avg)

      femaleVoiceMean = window.d2Mean
      femaleDelta = Math.abs(femaleVoiceMean - avg)

      if maleDelta > femaleDelta
        # guess it's female
        document.getElementById("d3Guess").textContent = "Female voice"
      else
        # guess it's male?
        document.getElementById("d3Guess").textContent = "Male voice"

  logPitch: ->
    if logging = true
      logIndex = logs.length-1
      if @ac isnt -1
        logs[logIndex].push(Math.round(@ac))
        # update histogram
        graph = document.getElementById("graphs")
        start = 0
        end = 1000
        size = 2

        ###
        data = []
        for vals in logs
          data.push(
            x: vals
            opacity: 0.75
            type: "histogram"
            autobinx: false
            xbins:
              start: start
              end: end
              size: size
          )
        ###

        # Plotly.newPlot(graph, data)

  startLoggingPitch: ->
    logging = true
    ###
    graph = document.createElement("div")
    graph.id = "graph_#{logs.length}"
    graph.setAttribute("class", "graph")
    document.getElementById("graphs").appendChild(graph)
    ###
    logs.push([])

  stopLoggingPitch: ->
    logging = false

root.PitchDetect = PitchDetect
