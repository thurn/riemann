# Project Riemann data model

# The state of a given game is represented by a document in the games
# collection:
# Game {
#   xPlayer: UserID
#   oPlayer: UserID
#   currentPlayer: UserID
#   moves: [{
#     row: Number - Square row number (numbered from zero)
#     column: Number - Square column number (numbered from zero)
#     isX: Boolean - True if square is "X", false if "O"
#   }]
# }

noughts.Games = new Meteor.Collection("games")

Meteor.methods
  # Create a new game against the specified user. Current user is "X". Returns
  # the document ID of the newly created game.
  createGame: (opponentId) ->
    noughts.Games.insert
      xPlayer: this.userId
      oPlayer: opponentId
      currentPlayer: xPlayer
      moves: []
  facebookLogin: (fbUser, accessToken) ->
    serviceData =
      id: fbUser.id
      accessToken: accessToken
      email: fbUser.email
    options =
      profile:
        name: fbUser.email
    console.log 'facebook login'
    Accounts.updateOrCreateUserFromExternalService(
        'facebook',serviceData, options).id
