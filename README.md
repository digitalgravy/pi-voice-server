# Pi Voice Server

![version 0.1.0](https://img.shields.io/badge/version-0.1.0-lightgrey.svg?style=flat-square)
![MIT license](https://img.shields.io/badge/license-MIT-blue.svg?style=flat-square)

Also known as "**Imogen**", the Pi Voice Server (PVS) is a prototype voice command Intelligent Personal Assistant (iPA). This was built for a presentation given at [Digital People in Peterborough](http://mydpip.com/2016/01/dpip-13th-january-2016-recap/) on 13th January 2016. 

At the presentation the PVS was demoed as an 'intelligent mirror' that spoke back to you when you talked to it. For further information, refer to the [slides from the presentation](http://slides.com/stuartelmore/ipa) or ~~read the blog post about it~~ (coming soon).

## Technology

* HTML5 SpeechRecognition
* HTML5 SpeechSynthesis
* Node.js (with Express)
* Websockets
* MongoDB (or other database)

PVS uses HTML5 [SpeechRecognition](https://developer.mozilla.org/en-US/docs/Web/API/SpeechRecognition) api, communication through websockets to a Node.js server which uses [Term Frequency-Inverse Document Frequency](https://en.wikipedia.org/wiki/Tf%E2%80%93idf) (Tf-Idf) to match to a command stored in a database (currently MongoDB - could be any). Once a match is found, a process is completed in the corresponding module and then optionally a data packet is sent back to the HTML page through websockets and optionally emits a response using the [SpeechSynthesis](https://developer.mozilla.org/en-US/docs/Web/API/SpeechSynthesis) api.

## Disclaimer

**This codebase was created as a prototype in a short period of time, and as such does not contain any tests and may contain code that contains little logic or infinite loops. You may not hold me liable for any problems that may occur by following these instructions or using this codebase.**

## voice-server

The `voice-server` element of the PVS system essentially matches the parsed voice command with a database of matches using the Tf-Idf technique. The matches are then associated with a corresponding 'module' that is then triggered.

### Modules

The modules house the logic around each command. Each module has `runServerSide` and `runClientSide` methods which are run sequentially, with the `runServerSide` occuring first. This is to allow you to differentiate the difference between events sent back to the client or to be run in the server's environment. **_Currently, all modules only emit client-side events._**

The module can be complex or simple. For example, the [`sayhello`](lib/modules/sayhello.coffee) module simply emits a command back to the webpage:

> **nb:** All code is written in [Coffeescript](http://coffeescript.org/)

```coffeescript
  runClientSide: =>
    new Promise (resolve, reject) =>
      @socket.emit("speech", speak: "Hello everyone")
      resolve()
```

Alternatively, the module can be complex. For an example of this, take a look at the [`weather`](lib/modules/weather.coffee) module.

### Adding commands

PVS requires commands to be associated with the modules, so with this in mind, an 'admin'-style page was cobbled together to allow a user to add new commands to the system. When PVS is running you can access it by going to [https://localhost/admin](https://localhost/admin).

Each command needs a set of documents to learn from. For example, to ask the system about the weather, the user may say:

> What is the weather?

However, this would not account for questions about the weather that do **not** include the keyword of `weather`. So with this in mind you could tell the system to train more commands as examples:

> What is the weather like today?

> What is it like outside?

> Should I take an umbrella today?

> Is it raining?

> Is it sunny?

The more example commands you can provide; the more accurate the learning will become. For more information on this please refer to the fantastic resource [Tf-idf.com](http://www.tfidf.com/) and the [slides regarding which style of string parsing from the presentation](http://slides.com/stuartelmore/ipa#/13).

## Running it yourself

The system is designed to run on a [Raspberry Pi 2 Model B](https://www.raspberrypi.org/products/raspberry-pi-2-model-b/), but can run on any device with access to a 'modern' web browser (i.e. Chrome / Chromium / Firefox), an audio input and an audio output. To run PVS you will need [Node.js](https://nodejs.org/en/), with [Coffeescript](http://coffeescript.org/) installed. Once you have Node.js installed on your platform you can do the following to install Coffeescript globally on your system:

```shell
npm install coffee-script -g
```

You will also need an install of [MongoDB](https://www.mongodb.org/). If you're running the PVS on a Raspberry Pi, I would recommend using one of the pre-compiled binaries of MongoDB as it's an absolute nightmare trying to get it to install from source. For this, I'd recommend following [this brilliant tutorial](http://www.widriksson.com/install-mongodb-raspberrypi/) by Jonas Widriksson.

Once you've got those, you'll also need to install the NPM dependencies. From within the directory of the project, execute:

```shell
npm install
```

Next, you'll need to generate the self-signed SSL certificates so that Node.js can serve the website over HTTPS (click [here](http://superuser.com/questions/596378/always-allow-microphone-usage-in-google-chrome) for why it must be served over SSL). There is a script that will do this for you:

```shell
node makepem.js
```

Now you're about ready to run PVS. From within the directory of the project, execute:

```shell
coffee server.coffee
```

> **Note:** As PVS uses SSL to serve the project, you may need to run this command as a privileged user with: `sudo coffee server`

If you recieve `Error: listen EADDRINUSE` when running this then you will need to disable your currently running webserver. On a Mac this may be the built in Apache server. On Windows this may be IIS.

### Running the server on alternate ports

To run on ports other than the default `443`, you can provide alternatives using the `--port` flag, for example:

```shell
coffee server.coffee --port=8080
```

To run the server **without** SSL, use the `useSSL` flag:

```shell
coffee server.coffee --useSSL=false
```

For example, to have the server listen on [http://localhost:8085](http://localhost:8085) use this:

```shell
coffee server.coffee --useSSL=false --port=8085
```

### Changing the name from "Imogen"

PVS relies on the user to say a keyword before listening to any commands. This is currently set as `Imogen`. You can change this by modifying the client initialisation script in the [index.html](public/index.html) page. Below you can see the initialisation script, and you will need to modify the `givenName` property. 

```javascript
$(document).ready(function(){
  var socket = io.connect('https://localhost');
  voiceClient = new VoiceClient({
    givenName: "imogen",
    socket: socket,
    waveform: $('#waveform'),
    debug: $('#transcript')
  });
});
```

> In theory you could create a random name to listen to on each instance of the index.html being run in the browser. By passing the `givenName` property to the `VoiceClient`, it allows the script to create a new `SpeechGrammar` item for the exact name. This helps to persuade the speech recognition towards correctly parsing the name we provide. 

### Modifying the client side code

The client side libraries of `client-x.js`, `datetime-x.js` and `waveform-x.js` are created from their corresponding `coffeescript` files. You can edit the Coffeescript files and have them automatically converted to Javascript when you save them by running this line in your console from the root directory of the project:

```shell
coffee -wc public/js/*.coffee
```

## The future of PVS

[DPiP are currently planning a workshop in March around creating your own PVS](http://www.meetup.com/Digital-People-in-Peterborough/events/228198875/).

I will continue to work on the project, adding more functionality, hopefully some testing and will happily accept sane pull requests. 💩

## License

[MIT License](LICENSE)
