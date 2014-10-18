require! 'express'
require! 'mongoose'
require! 'body-parser'
require! 'moment'
{all, map} = require 'prelude-ls'

mongoose.connect 'mongodb://localhost/kikkeri'
gameSchema = mongoose.Schema {
  teams: [{
    players: [String]
    score: Number
  }]
  timestamp: Date
}

Game = mongoose.model 'Game', gameSchema

app = do express
app.use('/web', express.static (__dirname + '/web'))
app.use(bodyParser.json {})
app.locals.moment = moment
app.set('views', __dirname + '/views')
app.set('view engine', 'jade')

app.get '/', (req, res) ->
  Game.find (err, games) ->
    res.render 'index', {games: games}

app.get '/game/', (req, res) ->
  Game.find (err, games) ->
    res.send games

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


app.listen 3000
