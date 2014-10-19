init = ->
  getJson "game/", (data) ->
    chartPlayerGames data
    chartPlayerSuccessIndex data
    chartPlayerWinRelations data

document.onreadystatechange = -> if document.readyState == "complete" then do init
