natural = require("natural")
Table = require("cli-table")
tokenizer = new natural.WordTokenizer()
TfIdf = natural.TfIdf

testPhrase = "what is the weather"

loggedPhrases =
  weather: [
    "what is the weather"
    "what's the weather like today"
    "what's it like outside"
  ]
  time: [
    "what is the time"
    "what time is it"
    "what's the time"
  ]
  stocks: [
    "how are my stocks"
    "how are my stocks looking"
    "are my stocks good today"
    "are my stocks bad"
  ]
  traffic: [
    "how is the traffic"
    "is traffic heavy today"
    "is traffic light"
    "is it busy on the roads"
    "time to get to work"
    "how long will it take to get to work today"
  ]
  train: [
    "when is my next train"
    "when does the next train leave"
    "will I be late for my train"
    "is my train on time today"
  ]
  events: [
    "what events do I have today"
    "what's happening today"
    "when is my next appointment today"
    "what appointments do I have today"
    "when is my first appointment"
  ]

incoming = [
  "what's the weather today"
  "what's the weather like"
  "what is the weather today"
  "what is it like outside"
  "is the weather good"
  "what's the weather like outside"
  "what is the time"
  "what time is it"
  "what's the time"
  "how are my stocks doing"
  "are my stocks looking good"
  "how is the traffic today"
  "is traffic heavy"
  "is traffic light"
  "how long will it take to get to work"
  "when is the next train"
  "is my train on time"
  "what have I got on today"
  "what events do I have today"
  "when is my first appointment"
  "when is my first event"
]

console.log "testPhrase: #{natural.PorterStemmer.tokenizeAndStem(testPhrase)}"
console.log "-------------------------------------"
console.log "      Tokenizing and Stemming"
console.log "-------------------------------------"
for phrase in incoming
  console.log "#{phrase} ::: #{natural.PorterStemmer.tokenizeAndStem(phrase)}"

console.log "\n-------------------------------------"
console.log "               TF-IDF"
console.log "-------------------------------------"
tfidf = new TfIdf()
subTable = new Table(
  head: [
    "phrase"
    "parsed"
    "confidence"
  ]
)
loggedPhrasesArr = []
for i, loggedPhrase of loggedPhrases
  tfidf.addDocument(loggedPhrase[0])
  loggedPhrasesArr.push([i, loggedPhrase[0]])
for phrase in incoming
  table = new Table(
    head: [ 
      "pos"
      "key"
      "measure"
    ]
  )
  sortedList = []
  tfidf.tfidfs(phrase, (i, measure) ->
    sortedList.push([loggedPhrasesArr[i][0], measure])
    #console.log "\t#{loggedPhrasesArr[i][0]} ::: #{measure}"
  )
  sortedList = sortedList.sort((a,b) ->
    b[1] - a[1]
  )
  for item, n in sortedList
    table.push([n, item[0], item[1]])
  #console.log "#{phrase}: #{sortedList[0][0]}"
  subTable.push([phrase, (if sortedList[0][1] is 0 then "" else sortedList[0][0]), sortedList[0][1]])
  #console.log table.toString(), "\n"
console.log subTable.toString()

console.log "\n-------------------------------------"
console.log "            TF-IDF - Multi"
console.log "-------------------------------------"
tfidf = new TfIdf()
subTable = new Table(
  head: [
    "phrase"
    "parsed"
    "confidence"
  ]
)
loggedPhrasesArr = []
for i, loggedPhrase of loggedPhrases
  for individual in loggedPhrase
    tfidf.addDocument(individual, i)
    loggedPhrasesArr.push([i, individual])
for phrase in incoming
  phraseKeys = {}
  tfidf.tfidfs(phrase, (i, measure) ->
    console.log arguments
    if not phraseKeys[loggedPhrasesArr[i][0]] then phraseKeys[loggedPhrasesArr[i][0]] = []
    phraseKeys[loggedPhrasesArr[i][0]].push(measure)
  )
  orgdKeys = []
  for key, measures of phraseKeys
    avg = 0
    count = 0
    for measure in measures
      avg = avg + measure
      count++
    if avg isnt 0 and count isnt 0
      avg = avg / count
    orgdKeys.push([key, avg])
  orgdKeys = orgdKeys.sort((a,b) ->
    b[1] - a[1]
  )
  table = new Table(
    head: [ 
      "pos"
      "key"
      "measure"
    ]
  )
  for key, avg of orgdKeys
    table.push([key, avg[0], avg[1]])
  #console.log "#{phrase}: #{orgdKeys[0][0]} - #{orgdKeys[0][1]}"
  subTable.push([phrase, (if orgdKeys[0][1] is 0 then "" else orgdKeys[0][0]), orgdKeys[0][1]])
  #console.log table.toString(), "\n"
console.log subTable.toString()




