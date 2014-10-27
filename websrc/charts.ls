onComplete ->
  getJson "../game/" + document.location.search, (data) ->
    chartPlayerGames data
    chartPlayerSuccessIndex data
    chartPlayerWinRelations data

