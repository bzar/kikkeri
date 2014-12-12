require! 'express'
require! 'mongoose'
require! 'body-parser'
require! 'moment'
require! './config'
require! './table-view'

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

mongoose.connect 'mongodb://localhost/kikkeri', ->
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

  app.get '/table/', (req, res) ->
    pipeline = req-to-game-aggregate-pipeline req
    Game.aggregate pipeline, (err, games) ->
      if err
        res.status(500).send {success: false, reason: err}
      else
        data = table-view.process-game-table-data games
        res.render 'table', { config: config, query: req.query, data: data }

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

  app.listen 3000

function parseOr(words)
  return parseInclude(words).concat(words |> filter (!= /^[-]/) |> filter (!= /^[!]/) 

function parseInclude(words)
  return words |> filter (== /^[!]/) |> map (.substring(1))  

function parseExclude(words)
  return words |> filter (== /^[-]/) |> map (.substring(1)) 

function req-to-game-aggregate-pipeline(req)
  query-list = (p) -> if req.query[p] then req.query[p].split(/[, ]+/)

  criteria-game-tags = (tags) ->
    | not tags? or empty parseOr(tags) => []
    | otherwise => [{$match: {tags: {$in: parseOr(tags)}}}]

  criteria-must-game-tags = (tags) ->
    | not tags? or empty parseInclude(tags) => []
    | otherwise => [{$match: {tags: {$all: parseInclude(tags)}}}]

  criteria-exclude-game-tags = (tags) ->
    | not tags? or empty parseExclude(tags) => []
    | otherwise => [{$match: {tags: {$nin: parseExclude(tags)}}}]

  criteria-players = (names) ->
    | not names? or empty parseOr(names) => []
    | otherwise => [{$match: {teams: {$elemMatch: {players: {$in: parseOr(names)}}}}}]

  criteria-must-players = (names) ->
    | not names? or empty parseInclude(names) => []
    | otherwise => [{$match: {teams: {$elemMatch: {players: {$all: parseInclude(names)}}}}}]

  criteria-exclude-players = (names) ->
    | not names? or empty parseExclude(names) => []
    | otherwise => [{$match: {teams: {$not: {$elemMatch: {players: {$in: parseExclude(names)}}}}}}]

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

  gameTags = query-list 'gameTags'
  excludeGameTags = query-list 'gameTags'
  mustGameTags = query-list 'gameTags'
  players = query-list 'players'
  excludePlayers = query-list 'players'
  mustPlayers = query-list 'players'
  numPlayers = parseInt req.query.numPlayers
  date-since =  new Date(Date.parse(req.query.since) - 1)
  date-until = new Date(Date.parse(req.query.until) + 24*60*60*1000)
  limit = parseInt req.query.limit
  sorting = [{$sort: {timestamp: -1}}]

  pipeline = concat [
    criteria-game-tags gameTags
    criteria-exclude-game-tags excludeGameTags
    criteria-must-game-tags mustGameTags
    criteria-players players
    criteria-exclude-players excludePlayers
    criteria-must-players mustPlayers
    criteria-num-players numPlayers
    criteria-date-since date-since
    criteria-date-until date-until
    sorting
    criteria-limit limit
  ]
  return pipeline

