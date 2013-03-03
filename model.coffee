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

noughts.Games.allow
  insert: (userId, game) ->
    game.xPlayer == userId or game.oPlayer == userId
  update: (userId, games) ->
    _.every games, (game) =>
      game.xPlayer == userId or game.oPlayer == userId

Meteor.methods
  # Used to set the user's facebook ID as the current Meteor ID
  setUserId: (id) -> this.setUserId(id)

  # Add the current player's symbol at the provided location if
  # this is a legal move
  performMoveIfLegal: (gameId, column, row) ->
    game = noughts.Games.findOne gameId
    if (game and game.currentPlayer == Meteor.userId() and
        _.every game.moves, (move) -> move.column != column and move.row != row)
      isXPlayer = game.currentPlayer == game.xPlayer
      noughts.Games.update gameId,
        $set:
          currentPlayer: if isXPlayer then game.oPlayer else game.xPlayer
        $push:
          moves: {column: column, row: row, isX: isXPlayer},
        (error) ->
          if error then throw error

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