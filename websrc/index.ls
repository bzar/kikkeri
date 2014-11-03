onComplete ->
  form = document.querySelector 'form'
  form.onsubmit = (e) ->
    do e.preventDefault
    splitList = -> (it.split /[, ]/).filter -> it

    game = {
      teams: [
        {
          players: splitList document.querySelector('#team1').value
          score: parseInt(document.querySelector('#score1').value)
        }
        {
          players: splitList document.querySelector('#team2').value
          score: parseInt(document.querySelector('#score2').value)
        }
      ]
      tags: splitList document.querySelector('#tags').value
    }

    postJson 'game/', game, (response) ->
      if response.success
        window.location.reload(false)

  document.querySelector('#previousTags').onchange = (e) ->
    document.querySelector('#tags').value = this.value
