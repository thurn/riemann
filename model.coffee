# The state of a given game is represented by a document in the games
# collection:
# Game {
#   xPlayer: UserID
#   oPlayer: UserID
#   currentPlayer: UserID
#   moves: [{
#     squareNumber: Number
#     isX: Boolean
#   }]
# }
root = exports ? this
root.Games = new Meteor.Collection("games")

checkLoggedIn = ->
  if not this.userId
    throw new Meteor.Error(403, "You must be logged in")

Meteor.methods
  # Create a new game against the specified user. Current user is "X". Returns
  # the document ID of the newly created game.
  createGame: (opponentId) ->
    checkLoggedIn()
    Games.insert
      xPlayer: this.userId
      oPlayer: opponentId
      currentPlayer: xPlayer
      moves: []