chartPlayerSuccessIndex = (data) ->
  {partition, maximum-by, sort-by, reverse, concat-map, map, group-by, sum, average} = require "prelude-ls"

  render = (data) ->
    parent = d3.select "\#chartPlayerSuccessIndex"
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
    x.domain [-1.1, 1.1]

    svg.append("g")
      .attr "class", "y axis"
      .call yAxis

    svg.append("g")
      .attr "class", "x axis"
      .attr "transform", "translate(0," + height + ")"
      .call xAxis

    bar = svg.selectAll(".bar")
      .data(data).enter()

    barClass = (d) ->
      | d.value > 0 => "positive bar"
      | d.value < 0 => "negative bar"
      | otherwise => "neutral bar"

    bar.append "rect"
      .attr "class", barClass
      .attr "x", 0
      .attr "y", (d) -> y(d.name)
      .attr "width", (d) -> x(d.value)
      .attr "height", y.rangeBand()

    bar.append "text"
      .attr "class", "barLabel"
      .attr "x", (d) -> x(d.value) - 4
      .attr "y", (d) -> y(d.name)  + 4
      .text (d) -> d.value.toFixed(2)

  gameWinScore = (g) -> (.score) <| maximum-by (.score), g.teams
  isWinner = (g) -> let s = gameWinScore g
    (t) -> t.score == s
  assignScore = (score, team) --> {players: team.players, score: score}
  teamPlayerScores = (t) -> [{name: name, score: t.score} for name in t.players]
  gamePlayerScores = (g) ->
    [winners, losers] = g.teams
      |> sort-by (.score)
      |> reverse
      |> partition (isWinner g)
    winnerScore = if winners.length > 1 then 0 else 1
    loserScore = -1
    scores =
      (map (assignScore winnerScore), winners) ++
      (map (assignScore loserScore), losers)
    concat-map teamPlayerScores, scores
  successIndex = (ss) -> average <| map (.score), ss
  playerGroupToValues = (ps) -> [{name: n, value: successIndex ss} for n, ss of ps]

  playerValues = data
    |> concat-map gamePlayerScores
    |> group-by (.name)
    |> playerGroupToValues
    |> sort-by (.value)
    |> reverse

  render playerValues


