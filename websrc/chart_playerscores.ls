chartPlayerScores = (data) ->
  {sort, sort-by, reverse, concat-map, count-by, id, unique-by, map, flatten, group-by, values} = require "prelude-ls"

  render = (data) ->
    parent = d3.select '#chartPlayerScores'
    margin = {top: 20, right: 20, bottom: 30, left: 140}
    width = parent[0][0].clientWidth - margin.left - margin.right
    height = parent[0][0].clientHeight - margin.top - margin.bottom

    svg = parent
      .append "svg"
        .attr "width", width + margin.left + margin.right
        .attr "height", height + margin.top + margin.bottom
        .append "g"
          .attr "transform", "translate(#{margin.left},#{margin.top})"

    x = d3.scale.linear()
      .range [0, width]

    y = d3.scale.ordinal()
      .rangeRoundBands [0, height], 0.1

    xAxis = d3.svg.axis()
      .scale x
      .orient "bottom"
      .ticks 10, ""

    yAxis = d3.svg.axis()
      .scale y
      .orient "left"

    y.domain <| data.map (.name)
    x.domain <| [0, d3.max(data, (.scores))]

    svg.append("g")
      .attr "class", "y axis"
      .call yAxis

    svg.append("g")
      .attr "class", "x axis"
      .attr "transform", "translate(0," + height + ")"
      .call xAxis

    bar = svg.selectAll(".bar")
      .data(data).enter()

    bar.append "rect"
      .attr "class", "bar"
      .attr "x", x(0)
      .attr "y", (d) -> y(d.name)
      .attr "width", (d) -> x(d.scores)
      .attr "height", y.rangeBand()

    bar.append "text"
      .attr "class", "barLabel"
      .attr "x", (d) -> x(d.scores) - 4
      .attr "y", (d) -> y(d.name)  + 4
      .text (.scores)

  separatePlayers = (obj) ->
    scores = (obj.score / obj.players.length)
    for x in obj.players
      { "name": x, "scores": scores}

  sumScores = (array) ->
    playerData = {name: "", scores: 0}
    for obj in array
      playerData.name = obj.name
      playerData.scores += obj.scores
    playerData

  freqData = data
    |> concat-map (.teams)
    |> map separatePlayers
    |> flatten
    |> group-by (.name)
    |> values
    |> map sumScores
    |> sort-by (.scores)
    |> reverse
  render freqData

