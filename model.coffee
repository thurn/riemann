# Project Riemann data model

# The state of a given game is represented by a document in the games
# collection:
# Game {
#   xPlayer: UserID
#   oPlayer: UserID
#   currentPlayer: UserID
#   requestId: Facebook request ID
#   moves: [{
#     column: Number - Square column number (numbered from zero)
#     row: Number - Square row number (numbered from zero)
#     isX: Boolean - True if square is "X", false if "O"
#   }]
# }

noughts.Games = new Meteor.Collection("games")

noughts.BadRequestError = (message) ->
  @error = 500
  @reason = message
  @name = "BadRequestError"
  @message = message || ""
  this
noughts.BadRequestError.prototype = new Meteor.Error()
noughts.BadRequestError.constructor = noughts.BadRequestError

# Translates a message into a BadRequestError
die = (msg) ->
  throw new noughts.BadRequestError(msg)

# Ensures that the provided userId is the ID of the current user
ensureIsCurrentUser = (userId) ->
  unless userId and Meteor.userId() and userId == Meteor.userId()
    die("Unauthorized user: '#{Meteor.userId()}'")

getGame = (gameId) ->
  game = noughts.Games.findOne(gameId)
  if game then game else die("Invalid game ID: '#{gameId}'")

Meteor.methods
  # Validate that the user has logged in as the Facebook user with ID "userId".
  authenticate: (userId, accessToken) ->
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

  # Add the current player's symbol at the provided location if
  # this is a legal move
  performMoveIfLegal: (gameId, column, row) ->
    game = getGame(gameId)
    ensureIsCurrentUser(game.currentPlayer)
    if _.some(game.moves, (move) -> move.column == column and move.row == row)
      # Space already taken!
      return
    isXPlayer = game.currentPlayer == game.xPlayer
    noughts.Games.update gameId,
      $set:
        currentPlayer: if isXPlayer then game.oPlayer else game.xPlayer
      $push:
        moves: {column: column, row: row, isX: isXPlayer}

  # Partially create a new game with no opponent specified yet
  newGame: (creatorId) ->
    ensureIsCurrentUser(creatorId)
    noughts.Games.insert
      xPlayer: creatorId
      currentPlayer: creatorId
      moves: []

  # Add an opponent to a partially-created game
  inviteOpponent: (gameId, opponentId, requestId) ->
    game = getGame(gameId)
    ensureIsCurrentUser(game.currentPlayer)
    die("game already has opponent") if game.oPlayer
    noughts.Games.update gameId,
      $set: {oPlayer: opponentId, requestId: requestId}

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
      return if move1.isX then game.xPlayer else game.oPlayer
  return false

# Returns true if this game is a draw, otherwise false.
noughts.isDraw = (game) -> game.moves.length == 9

