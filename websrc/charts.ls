onComplete ->
  getJson "../game/" + document.location.search, (data) ->
    chartPlayerGames data
    chartPlayerScores data
    chartPlayerSuccessIndex data
    chartPlayerWinRelations data

