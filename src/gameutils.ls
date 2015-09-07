{empty, any, all, filter, sort, group-by, map, concat-map, Obj} = require 'prelude-ls'

stringify-team = (t) ->
  t with players: sort(t.players).join(', ')

stringify-teams = (g) ->
  g with teams: map stringify-team, g.teams

with-teams-by-name = (g) ->
  g with teams_by_name: {[t.players, t] for t in g.teams}

game-by-team = (g) ->
  map (-> {team: it.players, game: g}), g.teams

games-by-team = (gs) ->
  gs
    |> concat-map game-by-team
    |> group-by (.team)
    |> Obj.map (map (.game))

team-in-game = (p, g) --> any (-> p === it.players), g.teams

games-by-opponent = (own, gs) ->
  gs
    |> filter (team-in-game own)
    |> concat-map game-by-team
    |> filter (-> it.team !== own)
    |> group-by (.team)
    |> Obj.map (map (.game))

#array-equal = (xs, ys) -> and-list <| zip-with (==), xs, ys
#in-order = (xss) -> all (-> it.length == 1), xss

#order-by-one = (fs, d, xs) -->
  #  fold ((ys, f) -> if array.equal(xs, ys) then f(ys, d) else ys), xs, fs

#order-each-by-one = (fs, xss, d) -> concat-map order-by-one(fs, d), xss

#order-by-many = (fs, xss, d) ->
  #  let ys = order-each-by-one fs, xss, d
    #    | in-order yss => flatten yss
#    | otherwise => order-by-many fs, yss, d
#
#order-by = (fs, xs, d) -> order-by-many fs, [xs], d

module.exports = {
  stringify-team,
  stringify-teams,
  games-by-team,
  games-by-opponent,
  with-teams-by-name,
#  order-by
  }
