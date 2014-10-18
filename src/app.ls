require! 'express'
require! 'mongoose'
require! 'body-parser'
require! 'moment'

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
app.set('views', './views')
app.set('view engine', 'jade')

app.get '/', (req, res) ->
  Game.find (err, games) ->
    res.render 'index', {games: games}

app.get '/game/', (req, res) ->
  Game.find (err, games) ->
    JSON.stringify games |> res.send

app.post '/game/', (req, res) ->
  game = new Game req.body
  game.timestamp = new Date()
  game.save (err) ->
    if not err?
      res.send '{"success": true}'
    else
      res.send JSON.stringify {success: false, reason: err}


app.listen 3000
