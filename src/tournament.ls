{reverse, sortBy, sum, group-by, concat, concat-map, sort, unique, Obj, filter, any, all, map} = require 'prelude-ls'
{
  stringify-teams,
  games-by-team,
  games-by-opponent,
  with-teams-by-name
} = require './gameutils'

{multisort, segment-by} = require './multisort'

team-data = (team, all-games) ->
  games = games-by-opponent team, all-games
  game-score = (g, o) ->
    if g.teams_by_name[team].score > g.teams_by_name[o].score then 1 else 0
  score = sum [(game-score g, o) for o, ogs of games for g in ogs]
  goals = sum [g.teams_by_name[team].score for o, ogs of games for g in ogs]
  count = sum [ogs.length for o, ogs of games]

  {games, score, goals, count}

enforce-min-games = (limit, gs) -->
  by-team = games-by-team gs
  discard = [t for t, tgs of by-team when tgs.length < limit]
  filter-game = (g) -> all (-> it.players not in discard), g.teams
  filter filter-game, gs

series-result = (team, series) ->
  own-score = series[team].score
  other-scores = [td.score for t, td of series when t is not team]
  rank = other-scores |> filter (> own-score) |> (.length) |> (+ 1)
  same-rank-count = other-scores |> filter (== own-score) |> (.length)
  if same-rank-count == 0 then return rank

  tied = series |> Obj.filter (-> it.score == own-score)
  console.log(tied)
  has-tied-teams = (g) -> g.teams |> all (-> it.players of tied)
  games-between-tied =
    tied
      |> Obj.values
      |> map (.games)
      |> concat-map Obj.values
      |> concat
      |> filter has-tied-teams

  console.log(games-between-tied)
  tied-data = {[t, team-data(t, games-between-tied)] for t of tied}
  better-ranking-tied = tied-data |> Obj.filter (-> it.goals > tied-data[team].goals)
  console.log(better-ranking-tied)
  return rank + (Obj.keys better-ranking-tied).length

sort-by-score = (xs, d) ->
  get-score = (team) ->
    games = games-by-opponent team, d
    game-score = (g, o) ->
      if g.teams_by_name[team].score > g.teams_by_name[o].score then 1 else 0
    sum [(game-score g, o) for o, ogs of games for g in ogs]
  td = {[t, (get-score t)] for t in xs}
  xs |> sort-by (-> td[it]) |> reverse |> segment-by (-> td[it])

sort-by-goals = (xs, d) ->
  get-goals = (team) ->
    games = games-by-opponent team, d
    sum [g.teams_by_name[team].score for o, ogs of games for g in ogs]
  td = {[t, (get-goals t)] for t in xs}
  xs |> sort-by (-> td[it]) |> reverse |> segment-by (-> td[it])

has-tag = (tag, game) --> game.tags.indexOf(tag) >= 0

module.exports.process-tournament-data = (games, min-games, quarterFinalTag, semiFinalTag, finalTag, consolationTag) ->
  games = games |> map stringify-teams |> map with-teams-by-name |> enforce-min-games min-games

  series-games = [g for g in games when not any (-> has-tag it, g), [quarterFinalTag, semiFinalTag, finalTag, consolationTag]]
  quarterFinal-games = filter (has-tag quarterFinalTag), games
  semiFinal-games = filter (has-tag semiFinalTag), games
  final-games = filter (has-tag finalTag), games
  consolation-games = filter (has-tag consolationTag), games

  series = series-games
    |> games-by-team
    |> Obj.obj-to-pairs
    |> map ([own, games]) -> [own, (team-data own, games)]
    |> Obj.pairs-to-obj

  final-order = multisort [sort-by-score, sort-by-goals], [team for team of series], series-games
  series-results = {[team, final-order.indexOf(team) + 1] for team of series}

  return {series, series-results}

