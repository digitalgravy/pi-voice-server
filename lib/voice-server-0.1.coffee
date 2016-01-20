# Promise library
Promise = require("promise")

# Database driver
DBConn = require("promised-mongo")

# Natural language suite
natural = require("natural")
tokenizer = new natural.WordTokenizer()
TfIdf = natural.TfIdf

class VoiceServer

  db = null
  docTfIdf = null
  docDict = {}
  docList = []

  constructor: ->
    @connectToDb().then(@updateCommands).catch((e) ->
      console.log "Error creating VoiceServer: ", e
    )

  connectToDb: ->
    new Promise (resolve, reject) ->
      if db
        resolve()
      else
        db = DBConn("VoiceServer", ["users", "commandList"])
        if db
          resolve()
        else
          reject()

  updateCommands: ->
    new Promise (resolve, reject) ->
      db.commandList.find().toArray().then( (docs) ->
        ###
          DOC:
            _id: int
            label: string
            examples: [string]
        ###
        docDict = {}
        docList = []
        docTfIdf = new TfIdf()
        # loop through docs and add them to docDict and their examples to docList
        for doc in docs
          docDict[doc.label] = doc
          for example in doc.examples
            docList.push([doc.label, example])
            docTfIdf.addDocument(example, doc.label)
        resolve()
      ).catch(reject)

  parseCommand: (command) ->
    new Promise (resolve, reject) ->
      # run the command through the tf-idf
      labelValues = {}
      docTfIdf.tfidfs(command, (index, measure, label) ->
        if not labelValues[label] then labelValues[label] = []
        labelValues[label].push(measure)
      )
      # get average for each label
      labelValuesArr = []
      for label, measurements of labelValues
        average = 0
        for measure in measurements
          average += measure
        if average isnt 0
          average = average / measurements.length
        # add to array
        labelValuesArr.push(label: label, average: average)
      # sort label array
      labelValuesArr = labelValuesArr.sort((a,b) ->
        b.average - a.average
      )
      # pick top value
      topLabel = labelValuesArr.slice(0, 1).shift()
      if topLabel.average > 0
        # get corresponding document
        resolve(doc: docDict[topLabel.label], certainty: topLabel.average)
      else
        reject()

  getDocList: ->
    new Promise (resolve, reject) ->
      docDictList = []
      for label, doc of docDict
        docDictList.push(doc)
      resolve(docDictList)

  addDocument: (doc) ->
    new Promise (resolve, reject) =>
      if not doc.label or not doc.examples
        reject()
      else
        db.commandList.save(
          label: doc.label
          examples: doc.examples.match(/[^\r\n]+/g)
          module: doc.module or ""
        )
        .then(@updateCommands)
        .then( ->
          resolve()
        ).catch( (e) ->
          reject(e)
        )

  updateDocument: (doc) ->
    new Promise (resolve, reject) =>
      if not doc._id
        reject()
      else
        id = doc._id
        delete doc._id
        set =
          label: doc.label
          examples: doc.examples.match(/[^\r\n]+/g)
          module: doc.module or ""
        db.commandList.findAndModify(
          query: 
            _id: DBConn.ObjectId(id)
          update:
            $set: set
        )
        .then(@updateCommands)
        .then(resolve)
        .catch(reject)

module.exports = VoiceServer