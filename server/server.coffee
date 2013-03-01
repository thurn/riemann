Meteor.publish "myGames", ->
  noughts.Games.find
    $or: [{xPlayer: this.userId}, {oPlayer: this.userId}]