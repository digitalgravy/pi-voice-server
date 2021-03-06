// Generated by CoffeeScript 1.10.0

/*
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
 */

(function() {
  var PitchDetect, getUserMedia, requestAnimationFrame, root;

  root = typeof exports !== "undefined" && exports !== null ? exports : this;

  requestAnimationFrame = this.requestAnimationFrame || this.webkitRequestAnimationFrame;

  getUserMedia = (function(_this) {
    return function(dictionary, callback, error) {
      _this.navigator.getUserMedia = _this.navigator.getUserMedia || _this.navigator.webkitGetUserMedia;
      return _this.navigator.getUserMedia(dictionary, callback, error);
    };
  })(this);

  PitchDetect = (function() {
    var analyser, audioContext, buffer, emptyCount, logging, logs, mediaStreamSource, voiceGuess;

    buffer = new Float32Array(1024);

    mediaStreamSource = null;

    analyser = null;

    audioContext = null;

    logs = [];

    logging = false;

    voiceGuess = [];

    emptyCount = 0;

    function PitchDetect(opts) {
      audioContext = new AudioContext();
      getUserMedia({
        audio: {
          mandatory: {
            googEchoCancellation: false,
            googAutoGainControl: false,
            googNoiseSuppression: false,
            googHighpassFilter: false
          },
          optional: []
        }
      }, (function(_this) {
        return function(stream) {
          mediaStreamSource = audioContext.createMediaStreamSource(stream);
          analyser = audioContext.createAnalyser();
          analyser.fftSize = 2048;
          mediaStreamSource.connect(analyser);
          return _this.update();
        };
      })(this), function(ex) {
        return console.log("getUserMedia threw exception: " + ex);
      });
    }

    PitchDetect.prototype.update = function() {
      analyser.getFloatTimeDomainData(buffer);
      this.ac = this.autoCorrelate(buffer, audioContext.sampleRate);
      this.displayPitch();
      return this.guessVoice();
    };

    PitchDetect.prototype.autoCorrelate = function(buffer, sampleRate) {
      var MAX_SAMPLES, MIN_SAMPLES, SIZE, best_correlation, best_offset, correlation, correlations, foundGoodCorrelation, i, j, k, lastCorrelation, num, offset, ref, ref1, ref2, ref3, rms, shift, val;
      SIZE = buffer.length;
      MIN_SAMPLES = 0;
      MAX_SAMPLES = Math.floor(SIZE / 2);
      best_offset = -1;
      best_correlation = 0;
      rms = 0;
      foundGoodCorrelation = false;
      correlations = new Array(MAX_SAMPLES);
      for (num = i = 0, ref = SIZE - 1; 0 <= ref ? i <= ref : i >= ref; num = 0 <= ref ? ++i : --i) {
        val = buffer[num];
        rms += val * val;
      }
      rms = Math.sqrt(rms / SIZE);
      if (rms < 0.01) {
        return -1;
      } else {
        lastCorrelation = 1;
        for (offset = j = ref1 = MIN_SAMPLES, ref2 = MAX_SAMPLES; ref1 <= ref2 ? j <= ref2 : j >= ref2; offset = ref1 <= ref2 ? ++j : --j) {
          correlation = 0;
          for (num = k = 0, ref3 = MAX_SAMPLES; 0 <= ref3 ? k <= ref3 : k >= ref3; num = 0 <= ref3 ? ++k : --k) {
            correlation += Math.abs(buffer[num] - buffer[num + offset]);
          }
          correlation = 1 - (correlation / MAX_SAMPLES);
          correlations[offset] = correlation;
          if (correlation > 0.9 && correlation > lastCorrelation) {
            foundGoodCorrelation = true;
            if (correlation > best_correlation) {
              best_correlation = correlation;
              best_offset = offset;
            }
          } else if (foundGoodCorrelation) {
            shift = (correlations[best_offset + 1] - correlations[best_offset - 1]) / correlations[best_offset];
            return sampleRate / (best_offset + (8 * shift));
          }
          lastCorrelation = correlation;
        }
        if (best_correlation > 0.01) {
          return sampleRate / best_offset;
        }
        return -1;
      }
    };

    PitchDetect.prototype.displayPitch = function() {
      var ac;
      ac = this.ac === -1 ? "--" : Math.round(this.ac);
      console.log("Pitch: " + ac + "Hz, guesses: " + voiceGuess.length);
      return requestAnimationFrame((function(_this) {
        return function() {
          _this.update();
          if (logging === true) {
            return _this.logPitch();
          }
        };
      })(this));
    };

    PitchDetect.prototype.guessVoice = function() {
      var avg, count, end, femaleDelta, femaleVoiceMean, i, len, maleDelta, maleVoiceMean, pauseLength, sampleSize, start, val;
      start = 0;
      end = window.HighPoint;
      sampleSize = 100;
      pauseLength = 50;
      if (this.ac === -1) {
        return emptyCount = emptyCount + 1;
      } else {
        if (emptyCount > pauseLength) {
          voiceGuess = [];
        }
        emptyCount = 0;
        voiceGuess.push(this.ac);
        if (voiceGuess.length > sampleSize) {
          voiceGuess = voiceGuess.splice(voiceGuess.length - sampleSize);
        }
        avg = 0;
        count = 0;
        for (i = 0, len = voiceGuess.length; i < len; i++) {
          val = voiceGuess[i];
          if (val > start && val < end) {
            avg += val;
            count = count + 1;
          }
        }
        avg = (avg / count).toFixed(1);
        document.getElementById("d3Mean").textContent = avg;
        maleVoiceMean = window.d1Mean;
        maleDelta = Math.abs(maleVoiceMean - avg);
        femaleVoiceMean = window.d2Mean;
        femaleDelta = Math.abs(femaleVoiceMean - avg);
        if (maleDelta > femaleDelta) {
          return document.getElementById("d3Guess").textContent = "Female voice";
        } else {
          return document.getElementById("d3Guess").textContent = "Male voice";
        }
      }
    };

    PitchDetect.prototype.logPitch = function() {
      var end, graph, logIndex, size, start;
      if (logging = true) {
        logIndex = logs.length - 1;
        if (this.ac !== -1) {
          logs[logIndex].push(Math.round(this.ac));
          graph = document.getElementById("graphs");
          start = 0;
          end = 1000;
          return size = 2;

          /*
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
           */
        }
      }
    };

    PitchDetect.prototype.startLoggingPitch = function() {
      logging = true;

      /*
      graph = document.createElement("div")
      graph.id = "graph_#{logs.length}"
      graph.setAttribute("class", "graph")
      document.getElementById("graphs").appendChild(graph)
       */
      return logs.push([]);
    };

    PitchDetect.prototype.stopLoggingPitch = function() {
      return logging = false;
    };

    return PitchDetect;

  })();

  root.PitchDetect = PitchDetect;

}).call(this);
