onComplete ->
  getJson "../game/", (data) ->
    chartPlayerGames data
    chartPlayerSuccessIndex data
    chartPlayerWinRelations data

