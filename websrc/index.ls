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

postJson = (url, data, onload, onerror) ->
  request = new XMLHttpRequest();
  request.open('POST', url, true);
  request.setRequestHeader('Content-Type', 'application/json; charset=UTF-8');
  request.onload = ->
    onload(JSON.parse(request.responseText))
  request.onerror = onerror
  request.send(JSON.stringify(data));

getJson = (url, onload, onerror) ->
  request = new XMLHttpRequest();
  request.open('GET', url, true);
  request.onload = ->
    onload(JSON.parse(request.responseText))
  request.onerror = onerror
  request.send();

document.onreadystatechange = -> if document.readyState == "complete" then do init

