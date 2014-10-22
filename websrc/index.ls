onComplete ->
  form = document.querySelector 'form'
  form.onsubmit = (e) ->
    do e.preventDefault
    tagString = document.querySelector('#tags').value
    tags = if tagString then tagString.split /[, ]+/ else []
    game = {
      teams: [
        {
          players: [document.querySelector('#player1').value]
          score: parseInt(document.querySelector('#score1').value)
        }
        {
          players: [document.querySelector('#player2').value]
          score: parseInt(document.querySelector('#score2').value)
        }
      ]
      tags: tags
    }

    postJson 'game/', game, (response) ->
      if response.success
        window.location.reload(false)

