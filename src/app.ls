require! 'express'
require! 'mongoose'
require! 'body-parser'
require! 'moment'
{all, map} = require 'prelude-ls'

gameSchema = mongoose.Schema {
  teams: [{
    players: [String]
    score: Number
  }]
  timestamp: Date
  tags: [String]
}

Game = mongoose.model 'Game', gameSchema
mongoose.connect 'mongodb://localhost/kikkeri', ->
  app = do express
  app.use('/web', express.static (__dirname + '/web'))
  app.use(bodyParser.json {})
  app.locals.moment = moment
  app.set('views', __dirname + '/views')
  app.set('view engine', 'jade')

  app.get '/', (req, res) ->
    Game.find {}, null, {sort: {timestamp: -1}, limit: 5} (err, games) ->
      res.render 'index', {games: games}

  app.get '/charts/', (req, res) ->
    res.render 'charts'

  app.get '/game/', (req, res) ->
    format = req.accepts ['json', 'html']
    if not format
      res.status(500).send {success: false, reason: 'No suitable format available'}
      return

    Game.find (err, games) ->
      if err
        res.status(500).send {success: false, reason: err}
      else if format == 'json'
        res.send games
      else if format == 'html'
        res.render 'games', {games: games}

  app.post '/game/', (req, res) ->
    game = new Game req.body
    validScore = (s) -> s <= 10 and s >= 0
    if not (all validScore . (.score), game.teams)
      res.status(500).send {success: false, reason: 'invalid score'}
      return

    game.timestamp = new Date()
    game.save (err) ->
      if not err?
        res.send {"success": true}
      else
        res.status(500).send {success: false, reason: err}


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
        res.render 'game', {game: game}

  app.put '/game/:id/', (req, res) ->
    Game.findById (req.param 'id'), (err, game) ->
      if err
        res.status(500).send {success: false, reason: 'game not found'}
      else
        game.teams = req.body.teams
        game.tags = req.body.tags
        res.send {success: true}

  app.listen 3000

