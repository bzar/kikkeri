{
  sortBy
  sortWith
  map
  fold
  Obj
  maximumBy
  minimumBy
} = require 'prelude-ls'
{
  stringify-teams,
  games-by-team,
  games-by-opponent,
  with-teams-by-name
} = require './gameutils'

# Continuous Inflationary Ranking
module.exports.cir = (gs) ->
  transfer_coefficient = 0.05
  inflation_rate_points = 100

  score-game = (rs, g) ->
    winner = g.teams |> maximum-by (.score)
    loser = g.teams |> minimum-by (.score)
    winner_rating = rs[winner.players] || 0
    loser_rating = rs[loser.players] || 0
    transfer = loser_rating * transfer_coefficient
    rs[winner.players] = winner_rating + transfer + inflation_rate_points
    rs[loser.players] = loser_rating - transfer
    rs

  scores = fold score-game, {}, (map stringify-teams, gs)

  scores
    |> Obj.obj-to-pairs
    |> map ([t, s]) -> {name: t, score: s}
    |> sort-with (a, b) -> b.score - a.score
    |> map (x) -> x with score: parseInt(x.score)
