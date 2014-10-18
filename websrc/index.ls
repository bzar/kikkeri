init = ->
  form = document.querySelector 'form'
  form.onsubmit = (e) ->
    do e.preventDefault
    game = {
      teams: [
        {
          players: [document.querySelector("\#player1").value]
          score: parseInt(document.querySelector("\#score1").value)
        }
        {
          players: [document.querySelector("\#player2").value]
          score: parseInt(document.querySelector("\#score2").value)
        }
      ]
    }

    postJson 'game/', game, (response) ->
      if response.success
        window.location.reload(false)

document.onreadystatechange = -> if document.readyState == "complete" then do init

