{reverse, sortBy, sum, group-by, concat, concat-map, sort, unique, Obj, filter, any, all, map, find, maximum-by, count-by, id, difference} = require 'prelude-ls'
{
  stringify-teams,
  games-by-team,
  games-by-opponent,
  with-teams-by-name
} = require './gameutils'

{multisort, segment-by} = require './multisort'

has-tag = (tag, game) --> game.tags.indexOf(tag) >= 0
is-game-between = (teams, game) --> all (-> it of game.teams_by_name), teams
is-game-between-some-of = (teams, game) --> all (-> it in teams), [t for t of game.teams_by_name]
winner-of = (game) -> game.teams |> maximum-by (.score) |> (.players)
winner-of-games = (games) ->
  games
    |> map winner-of
    |> count-by id
    |> Obj.obj-to-pairs
    |> maximum-by (-> it[1])
    |> (-> if it then it[0] else null)

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

sort-by-score = (xs, d) ->
  gs = filter (is-game-between-some-of xs), d
  get-score = (team) ->
    games = games-by-opponent team, gs
    game-score = (g, o) ->
      if g.teams_by_name[team].score > g.teams_by_name[o].score then 1 else 0
    sum [(game-score g, o) for o, ogs of games for g in ogs]
  td = {[t, (get-score t)] for t in xs}
  xs |> sort-by (-> td[it]) |> reverse |> segment-by (-> td[it])

sort-by-goals = (xs, d) ->
  gs = filter (is-game-between-some-of xs), d
  get-goals = (team) ->
    games = games-by-opponent team, gs
    sum [g.teams_by_name[team].score for o, ogs of games for g in ogs]
  td = {[t, (get-goals t)] for t in xs}
  xs |> sort-by (-> td[it]) |> reverse |> segment-by (-> td[it])


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
  nth-place = (n) -> final-order[n] or null

  quarterFinal-pairs = [[nth-place(i), nth-place(7-i)] for i til 4]
  quarterFinal-pair-games = [filter (is-game-between teams), quarterFinal-games for teams in quarterFinal-pairs]
  quarterFinal-winners = [winner-of-games gs for gs in quarterFinal-pair-games]
  semiFinal-pairs = [[quarterFinal-winners[i], quarterFinal-winners[3-i]] for i til 2]
  semiFinal-pair-games = [filter (is-game-between teams), semiFinal-games for teams in semiFinal-pairs]
  final-pair = [winner-of-games g for g in semiFinal-pair-games]
  final-pair-games = filter (is-game-between final-pair), final-games
  consolation-pair = semiFinal-pairs |> concat |> (-> difference it, final-pair)
  consolation-pair-games = filter (is-game-between consolation-pair), consolation-games
  data = {
    series
    series-results
    quarterFinal-pairs
    quarterFinal-pair-games
    semiFinal-pairs
    semiFinal-pair-games
    final-pair
    final-pair-games
    consolation-pair
    consolation-pair-games
  }
  console.log data

  return data

