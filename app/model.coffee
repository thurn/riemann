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
