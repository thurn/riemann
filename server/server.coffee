###
# To the extent possible under law, the author(s) have dedicated all copyright
# and related and neighboring rights to this software to the public domain
# worldwide. This software is distributed without any warranty. You should have
# received a copy of the CC0 Public Domain Dedication along with this software.
# If not, see <http://creativecommons.org/publicdomain/zero/1.0/>.
###

Meteor.publish "myGames", ->
  noughts.Games.find {players: this.userId}

Meteor.publish "gameActions", (gameId) ->
  noughts.Actions.find
    $and: [gameId: gameId, $or: [submitted: true, player: this.userId]]