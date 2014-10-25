{concat-map, filter, any, unique} = require "prelude-ls"

game-players = (game) ->
  concat-map (-> concat-map (.players), it), game.teams |> unique

filter-games-by-tags = (games, tags) -->
  games |> filter -> any (-> it in tags), it.tags

filter-games-by-players = (games, players) -->
  games |> filter (game) -> any (-> it in game-players game), players

