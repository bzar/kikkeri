{sum, group-by, concat, concat-map, sort, unique, Obj, filter, any, all, map} = require 'prelude-ls'
{
  stringify-teams, 
  games-by-team, 
  games-by-opponent, 
  with-teams-by-name
} = require './gameutils'

team-data = (team, all-games) ->
  games = games-by-opponent team, all-games
  game-score = (g, o) -> 
    if g.teams_by_name[team].score > g.teams_by_name[o].score then 1 else 0
  score = sum [(game-score g, o) for o, ogs of games for g in ogs]
  goals = sum [g.teams_by_name[team].score for o, ogs of games for g in ogs]
  count = sum [ogs.length for o, ogs of games]
  
  {games, score, goals, count}

enforce-min-games = (limit, gs) -->
  discard = [t for t, tgs of gs when tgs.length < limit]
  filter-game = (g) -> all (-> it.players not in discard), g.teams
  filter-games = (tgs) -> filter filter-game, tgs
  gs 
    |> Obj.obj-to-pairs
    |> filter (-> it[0] not in discard)
    |> Obj.pairs-to-obj
    |> Obj.map filter-games

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
  
module.exports.process-tournament-data = (games, min-games) ->
  series = games
    |> map stringify-teams
    |> map with-teams-by-name
    |> games-by-team
    |> enforce-min-games min-games
    |> Obj.obj-to-pairs
    |> map ([own, games]) -> [own, (team-data own, games)]
    |> Obj.pairs-to-obj

  series-results = {[team, series-result(team, series)] for team of series}
  return {series, series-results}

