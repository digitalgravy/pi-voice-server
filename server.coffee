fs = require("fs")
http = require("http")
https = require("https")
path = require("path")
express = require("express")
bodyParser = require("body-parser")
handlebars = require("express3-handlebars")
requireDir = require("require-dir")

# modules
Modules = requireDir("./lib/modules")

# voice server
VoiceServer = require("./lib/voice-server-0.1")
voiceServer = new VoiceServer()

# Server settings
SSLPort = 443
standardPort = 80
useSSL = true
customPort = null

# Deal with arguments
process.argv.forEach (key, index, array) ->
  if key.indexOf("--") > -1
    key = key.replace("--", "")
    if key.indexOf("=") > -1
      val = key.split("=")[1]
      key = key.split("=")[0]

    switch key
      when "useSSL"
        if val is "false"
          useSSL = false
      when "port"
        if val isnt ""
          customPort = parseInt(val, 10)

if useSSL is true
  options =
    key: fs.readFileSync(path.resolve(__dirname, "./ssl/serviceKey"), "utf8")
    cert: fs.readFileSync(path.resolve(__dirname, "./ssl/certificate"), "utf8")
else
  options = {}

if customPort is null
  port = if useSSL is true then SSLPort else standardPort
else
  port = customPort

# Express bits
app = express()
app.use(bodyParser())

# handlebars setup for admin
app.set("views", path.join(__dirname, "views"))
app.engine("handlebars", handlebars(extname: "handlebars", defaultLayout: "main"))
app.set("view engine", "handlebars")

app.use(express.static("public"))
app.use("/admin", require("./routes/admin")(voiceServer))

if useSSL is true
  server = https.createServer(options, app)
else
  server = http.createServer(app)
io = require("socket.io")(server)

server.listen(port, ->
  console.log "Server listening on port #{port}, with#{if useSSL is true then "" else "out"} SSL."
  console.log "  http#{if useSSL is true then "s" else ""}://localhost#{if customPort then ":"+customPort else ""}"
)

io.on("connection", (socket) ->
  socket.on("speech", (data) ->
    console.log new Date().toString(), "Recieved transcript: '#{data.transcript}'"
    timer = new Date().getTime()
    voiceServer.parseCommand(data.transcript)
    .then( (response) ->
      socket.emit("response", 
        label: response.doc.label
        certainty: response.certainty
        transcript: response.transcript
        time: new Date().getTime() - timer
      )
      moduleText = "but no module was associated."
      if response.doc.module
        moduleText = "and module of #{response.doc.module} was associated"
        if Modules[response.doc.module]
          moduleText += " and executed."
          foundModule = new Modules[response.doc.module](socket, data.transcript)
          foundModule.runServerSide().then(foundModule.runClientSide)
        else
          moduleText += " but not found."
      console.log new Date().toString(), "Found doc with certainty of #{response.certainty.toFixed(3)} and label of '#{response.doc.label}', for '#{data.transcript}' #{moduleText}"
    ).catch( (e) ->
      console.log new Date().toString(), "Couldn't find doc for '#{data.transcript}'", e
      socket.emit("response", 
        data: null
        error: "nothing found for '#{data.transcript}'"
        time: new Date().getTime() - timer
      )
    )
  )
)