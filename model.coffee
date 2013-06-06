###
# To the extent possible under law, the author(s) have dedicated all copyright
# and related and neighboring rights to this software to the public domain
# worldwide. This software is distributed without any warranty. You should have
# received a copy of the CC0 Public Domain Dedication along with this software.
# If not, see <http://creativecommons.org/publicdomain/zero/1.0/>.
###

# Project Riemann data model

# The state of a given game is represented by a document in the games
# collection:
#
# Game {
#   players: ([String]) List of player IDs in this game
#   currentPlayer: (Integer) Index of current player in the player list
#   requestId: (String) Facebook request ID associated with this game
#   moves: [{
#     column: Number - Square column number (numbered from zero)
#     row: Number - Square row number (numbered from zero)
#     isX: Boolean - True if square is "X", false if "O"
#   }]
# }
#
# By convention, players[0] is the game initiator and the "x" player, while
# players[1] is the "o" player.
#
# Security:
# There are a few intentionally insecure aspects of the system:
#
# - As a general rule, if you know the Game ID, you may modify the participants
#   in the game however you wish
# - If you know somebody's secret UUID (stored in their cookie), you can
#   impersonate them at will

noughts.Games = new Meteor.Collection("games")

noughts.BadRequestError = (message) ->
  @error = 500
  @reason = message
  @name = "BadRequestError"
  @message = message || ""
  this
noughts.BadRequestError.prototype = new Meteor.Error()
noughts.BadRequestError.constructor = noughts.BadRequestError

X_PLAYER = 0
O_PLAYER = 1

# Translates a message into a BadRequestError
die = (msg) ->
  console.log("ERORR: " + msg)
  throw new noughts.BadRequestError(msg)

# Ensures that the provided userId is the current player in the provided game
ensureIsCurrentPlayer = (game, userId) ->
  currentUser = game.players[game.currentPlayer]
  unless currentUser and userId and currentUser = userId
    die("Unauthorized user: '#{Meteor.userId()}'")

getGame = (gameId) ->
  game = noughts.Games.findOne(gameId)
  if game then game else die("Invalid game ID: '#{gameId}'")

Meteor.methods
  # Validate that the user has logged in as the Facebook user with ID "userId".
  facebookAuthenticate: (userId, accessToken) ->
    if Meteor.isServer
      result = Meteor.http.get "https://graph.facebook.com/me",
          params: {fields: "id", access_token: accessToken}
      responseUserId = JSON.parse(result.content)["id"]
      unless userId and responseUserId and responseUserId == userId
        die("invalid access token")
      this.setUserId(responseUserId)
    else
      # Don't need to check the user ID on the client
      this.setUserId(userId)

  # Logs the user in based on an anonymous user ID.
  anonymousAuthenticate: (uuid) ->
    this.setUserId(CryptoJS.SHA3(uuid, {outputLength: 256}).toString())

  # Add the current player's symbol at the provided location if
  # this is a legal move
  performMoveIfLegal: (gameId, column, row) ->
    game = getGame(gameId)
    ensureIsCurrentPlayer(game, this.userId)
    if _.some(game.moves, (move) -> move.column == column and move.row == row)
      # Space already taken!
      return
    if noughts.checkForVictory(game)
      # Game over!
      return
    isXPlayer = (game.currentPlayer == X_PLAYER)
    noughts.Games.update gameId,
      $set:
        currentPlayer: if isXPlayer then O_PLAYER else X_PLAYER
      $push:
        moves: {column: column, row: row, isX: isXPlayer}

  # Partially create a new game with no opponent specified yet
  newGame: ->
    noughts.Games.insert
      players: [this.userId]
      currentPlayer: X_PLAYER
      moves: []

  # Stores a facebook request ID with a game so that somebody invited via
  # Facebook can later find the game.
  facebookSetRequestId: (gameId, requestId) ->
    game = getGame(gameId)
    ensureIsCurrentPlayer(game, this.userId)
    die("game is full") if game.players.length >= noughts.Config.maxPlayers
    noughts.Games.update gameId,
      $set: {requestId: requestId}

  # If the current user is not present in game.players (and the game is not
  # full), add her to the player list.
  addPlayerIfNotPresent: (gameId) ->
    game = getGame(gameId)
    if (game.players.length < noughts.Config.maxPlayers and
        not _.contains(game.players, this.userId))
      noughts.Games.update gameId,
        $push: {players: this.userId}

  # Checks that a game exists based on its ID and that the current user is a
  # participant in it.
  validateGameId: (gameId) -> noughts.Games.findOne(gameId)

# Checks if somebody has won this game. If they have, returns the winner's
# user ID. Otherwise, returns false.
noughts.checkForVictory = (game) ->
  getMove = (column, row) ->
    _.find(game.moves, (x) -> x.column == column and x.row == row)

  # All possible winning lines in (col, row) format
  victoryLines = [ [[0,0], [1,0], [2,0]], [[0,1], [1,1], [2,1]],
      [[0,2], [1,2], [2,2]], [[0,0], [0,1], [0,2]], [[1,0], [1,1], [1,2]],
      [[2,0], [2,1], [2,2]], [[0,0], [1,1], [2,2]], [[2,0], [1,1], [0,2]] ]

  for line in victoryLines
    move1 = getMove(line[0][0], line[0][1])
    move2 = getMove(line[1][0], line[1][1])
    move3 = getMove(line[2][0], line[2][1])
    continue unless move1? and move2? and move3?
    if move1.isX == move2.isX and move2.isX == move3.isX
      return if move1.isX then game.players[X_PLAYER] else game.players[O_PLAYER]
  return false

# Returns true if this game is a draw, otherwise false.
noughts.isDraw = (game) -> game.moves.length == 9
