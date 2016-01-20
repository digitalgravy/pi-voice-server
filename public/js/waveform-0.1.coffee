root = exports ? this

# Organise globals
requestAnimationFrame = this.requestAnimationFrame or this.webkitRequestAnimationFrame
getUserMedia = (dictionary, callback, error) =>
  @navigator.getUserMedia = @navigator.getUserMedia or @navigator.webkitGetUserMedia
  @navigator.getUserMedia(dictionary, callback, error)

# Organise client
class WaveformClient
  buffer = new Float32Array(1024)
  jqCanvas = null
  canvas = null
  canvasContext = null
  mediaStreamSource = null
  analyser = null
  audioContext = null

  constructor: (opts) ->
    jqCanvas = opts.canvas
    jqCanvas.css(opacity: 0)
    canvas = jqCanvas.get(0)
    canvas.width = window.innerWidth * 0.8
    canvasContext = canvas.getContext("2d")
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
    @autoCorrelate(buffer, audioContext.sampleRate)
    @paintCanvas()

  autoCorrelate: (buffer, sampleRate) ->
    SIZE = buffer.length
    MIN_SAMPLES = 0
    MAX_SAMPLES = Math.floor(SIZE/2)
    best_offset = -1
    best_correlation = 0
    rms = 0
    foundGoodCorrelation = false
    correlations = new Array(MAX_SAMPLES)
    for num in [0..SIZE]
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

  paintCanvas: ->
    part = 100
    base = (Math.PI/2) / part
    zoom = 1
    volumeDupe = 100
    dist = canvas.width / 512
    mid = canvas.height / 2
    canvasContext.clearRect(0, 0, canvas.width, canvas.height)
    canvasContext.beginPath()
    canvasContext.lineTo(0, canvas.height / 2)
    # bottom
    for num in [0..512]
      if num < part
        zoom = Math.sin(base * num)
      else if num > 512 - part
        zoom = Math.sin(base * Math.abs(num - 512))
      else
        zoom = 1
      canvasContext.lineTo(dist * num, mid + (zoom * (Math.abs(buffer[num] * volumeDupe))))
    # top
    for num in [0..512]
      if num < part
        zoom = Math.sin(base * num)
      else if num > 512 - part
        zoom = Math.sin(base * Math.abs(num - 512))
      else
        zoom = 1
      canvasContext.lineTo(dist * num, mid + (0 - (zoom * (Math.abs(buffer[num] * volumeDupe)))))
    canvasContext.lineTo(canvas.width, mid)
    canvasContext.fillStyle = "rgba(255,255,255,0.8)"
    canvasContext.fill()
    requestAnimationFrame =>
      @update()

  show: ->
    jqCanvas.stop()
    jqCanvas.animate(opacity: 1, 500)

  hide: ->
    jqCanvas.stop().css(opacity: 0)

root.WaveformClient = WaveformClient