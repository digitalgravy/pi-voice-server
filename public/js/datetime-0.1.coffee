root = exports ? this

dateTimeElem = $("#date_time")
looper = ->
  dateTimeElem.find('.date').html("<span class='day'>#{moment().format("ddd")},</span> <span class='month'>#{moment().format("MMM")}</span> <span class='date_ordinal'>#{moment().format("Do")}</span> <span class='year'>#{moment().format("YYYY")}</span>")
  dateTimeElem.find('.time').text(moment().format("h:mma"))
setInterval( looper, 5000 )
looper()