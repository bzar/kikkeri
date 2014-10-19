init = ->
  getJson "game/", (data) ->
    chartPlayerGames data
    chartPlayerSuccessIndex data

document.onreadystatechange = -> if document.readyState == "complete" then do init
