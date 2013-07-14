###
# To the extent possible under law, the author(s) have dedicated all copyright
# and related and neighboring rights to this software to the public domain
# worldwide. This software is distributed without any warranty. You should have
# received a copy of the CC0 Public Domain Dedication along with this software.
# If not, see <http://creativecommons.org/publicdomain/zero/1.0/>.
###

Meteor.publish "me", ->
  return [
    noughts.Games.find({players: this.userId}),
    noughts.Actions.find({player: this.userId})
  ]

Meteor.publish "game", (gameId) ->
  game = noughts.Games.findOne(gameId)
  return [
    noughts.Games.find({_id: gameId})
    noughts.Actions.find({$and: [{gameId: gameId}, {submitted: true}]})
  ]
