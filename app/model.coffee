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
  setUserId: (id) -> this.setUserId(id)