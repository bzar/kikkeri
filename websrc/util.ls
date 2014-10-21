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
  request.setRequestHeader('Accept', 'application/json');
  request.onload = ->
    onload(JSON.parse(request.responseText))
  request.onerror = onerror
  request.send();


