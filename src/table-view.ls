{sum, group-by, concat-map, sort, unique, Obj, filter, any, all, map} = require 'prelude-ls'

module.exports.process-game-table-data = (rawData) ->
  stringify-team = (t) ->
    score: t.score
    players: sort(t.players).join(', ')
  stringify-teams = (g) ->
    teams: map stringify-team, g.teams
  data = rawData
    |> map stringify-teams

  teams = data
    |> concat-map (.teams)
    |> map (.players)
    |> unique

  team-in-game = (p, g) --> any (-> p == it.players), g.teams
  own-team = (p, g) -->
    | p == g.teams[0].players => g.teams[0]
    | otherwise => g.teams[1]

  opponent-team = (p, g) ->
    | p == g.teams[0].players => g.teams[1]
    | otherwise => g.teams[0]

  determine-teams = (p, g) -->
    own: own-team p, g
    opponent: opponent-team p, g

  team-games = (p) ->
    data
      |> filter (team-in-game p)
      |> map (determine-teams p)

  games-by-team = [[t, team-games t] for t in teams]
    |> Obj.pairs-to-obj
    |> Obj.map (group-by (.opponent.players))

  aggregate-results = (games) ->
    wins: filter (-> it.own.score > it.opponent.score), games |> (.length)
    losses: filter (-> it.own.score < it.opponent.score), games |> (.length)
    ties: filter (-> it.own.score == it.opponent.score), games |> (.length)
    games: games

  player-totals = (opponents) ->
    wins: map (.wins), Obj.values opponents |> sum
    losses: map (.losses), Obj.values opponents |> sum
    ties: map (.ties), Obj.values opponents |> sum
    opponents: opponents

  results = games-by-team
    |> Obj.map (Obj.map aggregate-results)
    |> Obj.map player-totals
  return results



