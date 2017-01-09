require! 'express'
require! 'mongoose'
require! 'body-parser'
require! 'request'
require! 'moment'
require! 'process'
require! './config'
require! './table-view'
require! './tournament'
require! './ranking'

{empty, concat, filter, any, all, map} = require 'prelude-ls'

gameSchema = mongoose.Schema {
  teams: [{
    players: [String]
    score: Number
  }]
  timestamp: Date
  tags: [String]
}

Game = mongoose.model 'Game', gameSchema

latestTags = (n, cb) ->
  pipeline = [
    {$match: {"tags.0": {$exists: true}}}
    {$project: {tags: 1, timestamp: 1, _id: 0}}
    {$group: {
      _id: "$tags",
      tags: {$first: "$tags"},
      timestamp: {$max: "$timestamp"}}}
    {$sort: {timestamp: -1}}
  ]
  if n?
    pipeline.push {$limit: n}
  Game.aggregate pipeline, (err, results) ->
    if err?
      cb err, []
    else
      tags = map (.tags), results
      cb err, tags

playerNames = (cb) ->
  pipeline = [
    {$unwind: "$teams"}
    {$unwind: "$teams.players"}
    {$group: {_id: "$teams.players"}}
    {$sort: {_id: 1}}
  ]

  Game.aggregate pipeline, (err, results) ->
    if err?
      cb err, []
    else
      names = map (._id), results
      cb err, names

mongodb_uri = process.env.MONGODB_URI || 'mongodb://localhost/kikkeri'
mongoose.connect mongodb_uri, ->
  app = do express
  app.use('/web', express.static (__dirname + '/web'))
  app.use(bodyParser.json {})
  app.locals.moment = moment
  app.set('views', __dirname + '/views')
  app.set('view engine', 'jade')

  app.get '/', (req, res) ->
    Game.find {}, null, {sort: {timestamp: -1}, limit: 5} (err, games) ->
      if err
        res.status(500).send {success: false, reason: err}
      else
        latestTags 10, (err, tags) ->
          if err
            res.status(500).send {success: false, reason: err}
          else
            res.render 'index', {config: config, games: games, tags: tags}

  app.get '/charts/', (req, res) ->
    res.render 'charts', { config: config, query: req.query }

  app.get '/ranking/', (req, res) ->
    pipeline = req-to-game-aggregate-pipeline req
    Game.aggregate pipeline, (err, games) ->
      if err
        res.status(500).send {success: false, reason: err}
      else
        data =
          cir: ranking.cir(games)
        res.render 'ranking', { config: config, query: req.query, data: data }

  app.get '/table/', (req, res) ->
    pipeline = req-to-game-aggregate-pipeline req
    Game.aggregate pipeline, (err, games) ->
      if err
        res.status(500).send {success: false, reason: err}
      else
        data = table-view.process-game-table-data games
        res.render 'table', { config: config, query: req.query, data: data }

  app.get '/tournament/', (req, res) ->
    if req.query.gameTags? and not empty req.query.gameTags
      pipeline = req-to-game-aggregate-pipeline req
      Game.aggregate pipeline, (err, games) ->
        if err
          res.status(500).send {success: false, reason: err}
        else
          {minimumGames, quarterFinalTag, semiFinalTag, finalTag, consolationTag} = req.query
          data = tournament.process-tournament-data games, minimumGames, quarterFinalTag, semiFinalTag, finalTag, consolationTag
          res.render 'tournament', { config: config, query: req.query, data: data }
    else
          res.render 'tournament', { config: config, query: req.query, data: null }


  app.get '/game/', (req, res) ->
    format = req.accepts ['json', 'html']
    if not format
      res.status(500).send {success: false, reason: 'No suitable format available'}
      return

    pipeline = req-to-game-aggregate-pipeline req
    Game.aggregate pipeline, (err, games) ->
      if err
        res.status(500).send {success: false, reason: err}
      else if format == 'json'
        res.send games
      else if format == 'html'
        res.render 'games', {config: config, query: req.query, games: games}

  app.post '/game/', (req, res) ->
    game = new Game req.body
    validScore = (s) -> s <= 10 and s >= 0
    if not (all validScore . (.score), game.teams)
      res.status(500).send {success: false, reason: 'invalid score'}
      return

    game.timestamp = new Date()
    game.save (err) ->
      if not err
        res.send {"success": true}
        post-to-slack(game)
      else
        res.status(500).send {success: false, reason: err}

  app.get '/game/tags/', (req, res) ->
    latestTags req.query.n, (err, tags) ->
      if err
        res.status(500).send {success: false, reason: err}
      else
        res.send tags

  app.get '/player/', (req, res) ->
    playerNames (err, names) ->
      if err
        res.status(500).send {success: false, reason: err}
      else
        res.send names

  app.get '/game/:id/edit/', (req, res) ->
    Game.findById (req.param 'id'), (err, game) ->
      if err
        res.status(500).send {success: false, reason: 'game not found'}
      else
        latestTags 10, (err, tags) ->
          if err
            res.status(500).send {success: false, reason: err}
          else
            res.render 'editgame', {config: config, game: game, tags: tags}

  app.get '/game/:id/', (req, res) ->
    format = req.accepts ['json', 'html']
    if not format
      res.status(500).send {success: false, reason: 'No suitable format available'}
      return

    Game.findById (req.param 'id'), (err, game) ->
      if err
        res.status(500).send {success: false, reason: 'game not found'}
      else if format == 'json'
        res.send game
      else if format == 'html'
        res.render 'game', {config: config, game: game}

  app.put '/game/:id/', (req, res) ->
    Game.findById (req.param 'id'), (err, game) ->
      if err
        res.status(500).send {success: false, reason: 'game not found'}
      else
        game.teams = req.body.teams
        game.tags = req.body.tags
        game.save()
        res.send {success: true}

  app.listen (process.env.PORT || 3000)

function req-to-game-aggregate-pipeline(req)
  query-list = (p) -> if req.query[p] then req.query[p].split(/[, ]+/)

  # Helpers to create set criteria
  parse-and = (words) ->
    | not words? or empty words => []
    | otherwise => words |> filter (== /^[+]/) |> map (.substring(1))

  parse-or = (words) ->
    | not words? or empty words => []
    | otherwise => words |> filter (!= /^[+-]/)

  parse-not = (words) ->
    | not words? or empty words => []
    | otherwise => words |> filter (== /^[-]/) |> map (.substring(1))

  # Search criteria
  criteria-or-game-tags = (tags) ->
    | not tags? or empty tags => []
    | otherwise => [{$match: {tags: {$in: tags}}}]

  criteria-and-game-tags = (tags) ->
    | not tags? or empty tags => []
    | otherwise => [{$match: {tags: {$all: tags}}}]

  criteria-not-game-tags = (tags) ->
    | not tags? or empty tags => []
    | otherwise => [{$match: {tags: {$nin: tags}}}]

  criteria-or-players = (names) ->
    | not names? or empty names => []
    | otherwise => [{$match: {teams: {$elemMatch: {players: {$in: names}}}}}]

  criteria-and-players = (names) ->
    | not names? or empty names => []
    | otherwise => [
      {$project: {
        _id: "$_id"
        players: "$teams.players"
        teams: "$teams"
        timestamp: "$timestamp"
        tags: "$tags"
      }}
      {$unwind: "$players"}
      {$unwind: "$players"}
      {$group: {
        _id: "$_id"
        all_players: {$addToSet: "$players" }
        teams: {$first: "$teams"}
        timestamp: {$first: "$timestamp"}
        tags: {$first: "$tags"}
      }}
      {$match: {all_players: {$all: names}}}]

  criteria-not-players = (names) ->
    | not names? or empty names => []
    | otherwise => [{$match: {teams: {$not: {$elemMatch: {players: {$in: names}}}}}}]

  criteria-num-players = (n) ->
    | not n > 0 => []
    | otherwise => [
      {$unwind: "$teams"}
      {$group: {
        _id: "$_id"
        number_of_players: {$sum: {$size: "$teams.players" }}
        teams: {$push: "$teams"}
        timestamp: {$first: "$timestamp"}
        tags: {$first: "$tags"}
      }}
      {$match: {number_of_players: n}}]

  criteria-date-since = (d) ->
    | not d.getYear() => []
    | otherwise => [{$match: {timestamp: {$gt: d}}}]

  criteria-date-until = (d) ->
    | not d.getYear() => []
    | otherwise => [{$match: {timestamp: {$lt: d}}}]

  criteria-limit = (n) ->
    | not n > 0 => []
    | otherwise => [{$limit: n}]

  orGameTags = parse-or <| query-list 'gameTags'
  notGameTags = parse-not <| query-list 'gameTags'
  andGameTags = parse-and <| query-list 'gameTags'
  orPlayers = parse-or <| query-list 'players'
  notPlayers = parse-not <| query-list 'players'
  andPlayers = parse-and <| query-list 'players'
  numPlayers = parseInt req.query.numPlayers
  date-since =  new Date(Date.parse(req.query.since) - 1)
  date-until = new Date(Date.parse(req.query.until) + 24*60*60*1000)
  limit = parseInt req.query.limit
  sorting = [{$sort: {timestamp: -1}}]

  pipeline = concat [
    criteria-or-game-tags orGameTags
    criteria-not-game-tags notGameTags
    criteria-and-game-tags andGameTags
    criteria-or-players orPlayers
    criteria-not-players notPlayers
    criteria-and-players andPlayers
    criteria-num-players numPlayers
    criteria-date-since date-since
    criteria-date-until date-until
    sorting
    criteria-limit limit
  ]
  return pipeline


post-to-slack = (game) ->
  game-has-tag-in = (tags) -> any (-> it in tags), game.tags

  teams = game.teams |> map (-> it.players.join(", ")) |> (-> it.join(" vs. "))
  scores = game.teams |> map (.score) |> (-> it.join(" - " ))
  tags = game.tags |> map (-> "##it") |> (-> it.join(" "))

  for item in config.slack.channelTags
    if not empty item.channel and game-has-tag-in item.tags
      message = JSON.stringify({text: "#teams => #scores #tags", channel: item.channel})
      form = {payload: message}
      if config.slack.incomingWebHookUrl
        request.post config.slack.incomingWebHookUrl, {form: form}
      else
        console.log form


