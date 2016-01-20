express = require("express")
router = express.Router()

module.exports = (voiceServer) ->

  router.get("/", (req, res) ->
    voiceServer.getDocList().then( (docList) ->
      res.render("admin", docList: docList)
    )
  )

  router.post("/create", (req, res) ->
    voiceServer.addDocument(req.body).then( ->
      res.redirect("/admin")
    ).catch( (e) ->
      console.log ">>> Error creating", req.body, e
      res.redirect("/admin")
    )
  )

  router.post("/update", (req, res) ->
    voiceServer.updateDocument(req.body).then( ->
      res.redirect("/admin")
    ).catch( (e) ->
      console.log ">>> Error updating", req.body, e
      res.redirect("/admin")
    )
  )

  router