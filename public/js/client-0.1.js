// Generated by CoffeeScript 1.10.0
(function() {
  var SpeechGrammar, SpeechGrammarList, SpeechRecognition, SpeechSynthesisUtterance, VoiceClient, requestAnimationFrame, root, speechSynthesis;

  root = typeof exports !== "undefined" && exports !== null ? exports : this;

  SpeechRecognition = this.SpeechRecognition || this.webkitSpeechRecognition;

  SpeechGrammar = this.SpeechGrammar || this.webkitSpeechGrammar;

  SpeechGrammarList = this.SpeechGrammarList || this.webkitSpeechGrammarList;

  SpeechSynthesisUtterance = this.SpeechSynthesisUtterance || this.webkitSpeechSynthesisUtterance;

  speechSynthesis = this.speechSynthesis || this.webkitSpeechSynthesis;

  requestAnimationFrame = this.requestAnimationFrame || this.webkitRequestAnimationFrame;

  VoiceClient = (function() {
    var allowedToListen, displayTimeout, finishedListeningBeep, listening, listeningBeep, listeningTimeout;

    listening = false;

    allowedToListen = false;

    listeningBeep = new Audio("/sounds/listening_dbl.wav");

    finishedListeningBeep = new Audio("/sounds/listened.wav");

    listeningTimeout = null;

    displayTimeout = null;

    function VoiceClient(opts) {
      var startListeningCommand, stopListeningCommand;
      this.socket = opts.socket;
      this.debugElem = opts.debug || $('<p>');
      this.outputElem = opts.output || $('<div>');
      this.confidenceElem = opts.confidence || $('<div>');
      this.givenName = opts.givenName;
      this.givenNameRegExp = new RegExp(this.givenName, 'i');
      this.listeningDelay = opts.listeningDelay || 5000;
      stopListeningCommand = opts.stopListening || "stop listening";
      this.stopListeningCommand = new RegExp(stopListeningCommand, 'i');
      startListeningCommand = opts.startListening || "continue listening";
      this.startListeningCommand = new RegExp(startListeningCommand, 'i');
      allowedToListen = opts.listeningByDefault || true;
      if (allowedToListen) {
        this.allowListening();
      } else {
        this.disallowListening();
      }
      if (opts.waveform) {
        this.waveform = new WaveformClient({
          canvas: opts.waveform
        });
      }
      this.initSpeech();
      this.initSocket();
    }

    VoiceClient.prototype.initSocket = function() {
      this.socket.on("response", (function(_this) {
        return function(data) {
          if (data.error === null && data.label) {
            return console.log("found match: '" + data.label + "' with a " + data.certainty + " certainty");
          }
        };
      })(this));
      return this.socket.on("speech", (function(_this) {
        return function(data) {
          console.log("Speaking... '" + data.speak + "'");
          return _this.speak(data.speak);
        };
      })(this));
    };

    VoiceClient.prototype.initSpeech = function() {
      var givenNameGrammar, givenNameGrammarList;
      this.recognition = new SpeechRecognition();
      this.recognition.lang = "en";
      this.recognition.continuous = true;
      this.recognition.interimResults = true;
      givenNameGrammar = new SpeechGrammar();
      givenNameGrammar.src = "#JSGF V1.0; grammar names; public <name> = " + this.givenName + ";";
      givenNameGrammarList = new SpeechGrammarList();
      givenNameGrammarList.addFromString(givenNameGrammar, 1);
      this.recognition.grammars = givenNameGrammarList;
      this.recognition.addEventListener("result", (function(_this) {
        return function(evt) {
          return _this.parseSpeech(evt);
        };
      })(this));
      this.recognition.addEventListener("end", (function(_this) {
        return function() {
          return _this.listenForSpeech();
        };
      })(this));
      this.recognition.addEventListener("start", function() {
        return console.log("Parsing speech...");
      });
      this.timeStartedListening = null;
      return this.listenForSpeech();
    };

    VoiceClient.prototype.speak = function(text) {
      var speechName, utterance, voices;
      this.cancelListening();
      utterance = new SpeechSynthesisUtterance(text);
      utterance.lang = "en-GB";
      speechName = "Google UK English Female";
      voices = speechSynthesis.getVoices();
      utterance.voice = voices.filter(function(voice) {
        return voice.name === speechName;
      })[0];
      utterance.onend = (function(_this) {
        return function(event) {
          console.log("Finished speaking.");
          return _this.listenForSpeech();
        };
      })(this);
      return speechSynthesis.speak(utterance);
    };

    VoiceClient.prototype.parseSpeech = function(event) {
      return requestAnimationFrame((function(_this) {
        return function() {
          var item, result, transcript;
          result = event.results[event.resultIndex];
          item = result[0];
          transcript = item.transcript.replace(/^\s+|\s+$/g, "");
          if (_this.givenNameRegExp.test(transcript) && listening === false) {
            _this.startListening();
          }
          if (allowedToListen === true) {
            _this.debugElem.text(transcript.replace(_this.givenNameRegExp, "").replace(/^\s+|\s+$/g, "")).css({
              opacity: result.isFinal ? 1 : 0.7,
              color: listening ? "#fff" : "#f00"
            });
            if (result.isFinal) {
              if (displayTimeout) {
                clearTimeout(displayTimeout);
              }
              _this.debugElem.stop();
              displayTimeout = setTimeout(function() {
                return _this.debugElem.animate({
                  opacity: 0
                }, 1000, function() {
                  return $(this).text("");
                });
              }, 5000);
            }
          }
          if (result.isFinal === true && listening === true) {
            transcript = transcript.replace(_this.givenNameRegExp, "").replace(/^\s+|\s+$/g, "");
            if (allowedToListen === false && _this.startListeningCommand.test(transcript)) {
              _this.allowListening();
            } else if (allowedToListen === true && _this.stopListeningCommand.test(transcript)) {
              _this.disallowListening();
            } else if (transcript !== "" && allowedToListen === true) {
              _this.stopListening();
              console.log("Got transcript: '" + transcript + "'");
              _this.socket.emit("speech", {
                transcript: transcript
              });
              _this.timeStartedListening = null;
              console.log("Stopped parsing speech...");
            }
          }
          if (result.isFinal === true) {
            return _this.restartService();
          }
        };
      })(this));
    };

    VoiceClient.prototype.restartService = function() {
      this.cancelListening();
      return this.listenForSpeech();
    };

    VoiceClient.prototype.cancelListening = function() {
      console.log("Stopping recognition.");
      return this.recognition.stop();
    };

    VoiceClient.prototype.abortListening = function() {
      try {
        this.recognition.abort();
        return console.log("Aborting recognition.");
      } catch (undefined) {}
    };

    VoiceClient.prototype.startListening = function() {
      listening = true;
      if (allowedToListen === true) {
        $("body").addClass("loading");
        console.log("listening...");
        listeningBeep.play(0);
        if (this.waveform) {
          this.waveform.show();
        }
      }
      if (listeningTimeout) {
        clearTimeout(listeningTimeout);
      }
      return listeningTimeout = setTimeout((function(_this) {
        return function() {
          return _this.stopListening();
        };
      })(this), this.listeningDelay);
    };

    VoiceClient.prototype.stopListening = function(notify) {
      if (notify == null) {
        notify = true;
      }
      $("body").removeClass("loading");
      if (listeningTimeout) {
        clearTimeout(listeningTimeout);
      }
      listening = false;
      if (allowedToListen === true) {
        console.log("finished listening.");
        if (this.waveform) {
          this.waveform.hide();
        }
        if (notify === true) {
          return finishedListeningBeep.play(0);
        }
      }
    };

    VoiceClient.prototype.allowListening = function() {
      this.stopListening(false);
      $("body").removeClass("listening_disabled");
      console.log("Now listening for commands.");
      allowedToListen = true;
      return listeningBeep.play(0);
    };

    VoiceClient.prototype.disallowListening = function() {
      this.stopListening();
      $("body").addClass("listening_disabled");
      console.log("No longer listening for commands.");
      allowedToListen = false;
      return finishedListeningBeep.play(0);
    };

    VoiceClient.prototype.listenForSpeech = function() {
      var e, error;
      try {
        console.log("Trying to start recognition...");
        this.recognition.start();
        return console.log("Starting recognition.");
      } catch (error) {
        e = error;
      }
    };

    return VoiceClient;

  })();

  root.VoiceClient = VoiceClient;

}).call(this);