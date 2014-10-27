chartPlayerWinRelations = (data) ->
  {empty, average, sum, Obj, any, filter, find, map, group-by, concat-map, maximum} = require "prelude-ls"
  render = (data) ->
    selected = null
    player-value = (p) -> average <| map (.total), p.totals

    refresh-data = ->
      nodes = data
        |> map (-> {name: it.name, value: player-value it})
      find-node = (p) -> find (-> it.name == p), nodes
      player-links = (p, rs) ->
        src = find-node p
        make-link = (r) -> {w: r.w, n: r.n, source: src, target: find-node r.opponent}
        filter (-> it.total > 0), rs
          |> filter (-> selected == null or p in selected or it.opponent in selected)
          |> map make-link
      links = concat-map (-> player-links it.name, it.totals), data
      return [nodes, links]

    parent = d3.select '#chartPlayerWinRelations'
    margin = {top: 20, right: 20, bottom: 20, left: 20}
    width = parent[0][0].clientWidth - margin.left - margin.right
    height = parent[0][0].clientHeight - margin.top - margin.bottom

    svg = parent
      .append "svg"
        .attr "width", width + margin.left + margin.right
        .attr "height", height + margin.top + margin.bottom
        .on "click", ->
          if selected != null
            selected := null
            do refresh
        .append "g"
          .attr "transform", "translate(#{margin.left},#{margin.top})"

    svg.append('svg:defs').append('svg:marker')
      .attr 'id', 'end-arrow'
      .attr 'viewBox', '0 -5 10 10'
      .attr 'refX', 6
      .attr 'markerWidth', 3
      .attr 'markerHeight', 3
      .attr 'orient', 'auto'
      .append 'svg:path'
      .attr 'd', 'M0,-5L10,0L0,5'
      .attr 'fill', '#aaa'

    path = svg.append('svg:g').selectAll('path')
    circle = svg.append('svg:g').selectAll('g')
    pathText = svg.append('svg:g').selectAll('text')

    tick = ->
      path.attr 'd', (d) ->
        deltaX = d.target.x - d.source.x
        deltaY = d.target.y - d.source.y
        dist = Math.sqrt(deltaX * deltaX + deltaY * deltaY)
        normX = deltaX / dist
        normY = deltaY / dist
        sourcePadding = 12
        targetPadding = 17
        sourceX = d.source.x + (sourcePadding * normX)
        sourceY = d.source.y + (sourcePadding * normY)
        targetX = d.target.x - (targetPadding * normX)
        targetY = d.target.y - (targetPadding * normY)
        "M#{sourceX},#{sourceY}L#{targetX},#{targetY}"

      circle.attr 'transform', (d) -> "translate(#{d.x},#{d.y})"
      pathText.attr 'transform', (d) ->
        x = d.source.x + (d.target.x - d.source.x) / 2
        y = d.source.y + (d.target.y - d.source.y) / 2
        "translate(#{x},#{y})"


    force = d3.layout.force()
      .size [width, height]
      .linkDistance 100
      .gravity 0.1
      .charge -500
      .on 'tick', tick

    refresh = ->
      [nodes, links] = do refresh-data
      force.nodes nodes
      force.links links
      path := path.data(links)
      circle := circle.data(nodes, (.name))
      pathText := pathText.data(links)
      path.enter().append('svg:path')
        .attr 'class', 'link'
        .style 'marker-end', 'url(#end-arrow)'

      path.exit().remove()

      pathText.enter().append('svg:text')
        .attr 'class', 'linkText'
        .attr 'y', '2px'

      pathText.text (-> parseInt(100 * it.w / it.n) + '%')
      pathText.exit().remove()

      g = circle.enter().append('svg:g')
      circle.exit().remove()

      g.append('svg:circle')
        .attr 'class', 'node'
        .attr 'r', 12
        .attr 'fill', ->
          | it.value < -0.25 => '#eaa'
          | it.value > 0.25 => '#aea'
          | otherwise => '#eea'

      g.append('svg:text')
        .attr 'class', 'id'
        .text (.name)

      circle.call force.drag
        .on 'click', (d) ->
          do d3.event.stopPropagation
          if not d3.event.defaultPrevented
            selected := [d.name]
            do refresh
      do force.start

    do refresh


  obj-to-list = (kname, vname, o) --> [{(kname): k, (vname): v} for k, v of o]
  nameGameList = (g) -> [{name: n, game: g} for t in g.teams for n in t.players]

  games-by-player = (games) ->
    games
      |> concat-map nameGameList
      |> group-by (.name)
      |> Obj.map (map (.game))
      |> obj-to-list "name", "games"

  playerGames = games-by-player data

  opponents = (p, g) ->
    g.teams
      |> filter (-> not (any (== p), it.players))
      |> concat-map (.players)

  playerScore = (p, g) ->
    g.teams
      |> filter (-> any (== p), it.players)
      |> map (.score)
      |> maximum

  winnerScore = (g) ->
    g.teams
      |> map (.score)
      |> maximum

  gameScoreResult = (p, g) ->
    ps = playerScore p, g
    ws = winnerScore g
    if ps < ws
      -1
    else if (g.teams |> map (.score) |> filter (== ws)).length > 1
      0
    else
      1

  gameResult = (p, g) --> {
    opponents: opponents p, g
    result: gameScoreResult p, g
  }

  playerResults = playerGames
    |> map (-> {name: it.name, results: map (gameResult it.name), it.games})

  playerOpponentResult = (r) -> [{opponent: o, result: r.result} for o in r.opponents]
  playerOpponentResults = (rs) ->
    rs
      |> concat-map playerOpponentResult
      |> group-by (.opponent)
      |> Obj.map (map (.result))
      |> obj-to-list "opponent", "results"

  playerOpponentResults = playerResults
    |> map (-> {name: it.name, results: playerOpponentResults it.results})

  playerTotals = (rs) ->
    [{opponent: r.opponent, total: (sum r.results), w: (filter (> 0), r.results).length, n: r.results.length} for r in rs]

  playerOpponentTotals = playerOpponentResults
    |> map (-> {name: it.name, totals: playerTotals it.results})


  render playerOpponentTotals

