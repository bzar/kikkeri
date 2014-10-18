init = ->
  do chartPlayerGames

document.onreadystatechange = -> if document.readyState == "complete" then do init
