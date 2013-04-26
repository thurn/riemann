###
# To the extent possible under law, the author(s) have dedicated all copyright
# and related and neighboring rights to this software to the public domain
# worldwide. This software is distributed without any warranty. You should have
# received a copy of the CC0 Public Domain Dedication along with this software.
# If not, see <http://creativecommons.org/publicdomain/zero/1.0/>.
###

# Project Riemann client interface

gameResources = [
  {name: "square", type: "image", src: "/tilemaps/square.jpg"},
  {name: "x", type: "image", src: "/images/x.png"},
  {name: "o", type: "image", src: "/images/o.png"},
  {name: "tilemap", type: "tmx", src: "/tilemaps/game.tmx"}
]

SPRITE_Z_INDEX = 2

getSuggestedFriends = ->
  return [] unless noughts.mutualFriends_ and noughts.appInstalled_
  installed = _.filter(noughts.mutualFriends_, (x) -> noughts.appInstalled_[x.uid])
  notInstalled = _.filter(noughts.mutualFriends_, (x) ->
      not noughts.appInstalled_[x.uid])
  return _.pluck(installed.concat(notInstalled), "uid")

showInviteDialog = (inviteCallback) ->
  suggestedFriends = getSuggestedFriends()
  if suggestedFriends
    filters = [{name: "Friends", user_ids: suggestedFriends}]
  else
    filters = ["app_non_users"]
  FB.ui
    method: "apprequests",
    title: "Select an opponent",
    filters: filters
    max_recipients: 1,
    message: "Want to play some Noughts?", inviteCallback

displayNotice = (msg) -> $(".nNotification").text(msg)

PlayScreen = me.ScreenObject.extend
  handleClick_: (tile) ->
    Meteor.call("performMoveIfLegal", Session.get("gameId"), tile.col, tile.row)

  loadMainLevel_: ->
    me.levelDirector.loadLevel("tilemap")
    @mainLayer_ = me.game.currentLevel.getLayerByName("mainLayer")

  onResetEvent: () ->
    $(".nIdNewGame").remove()
    $(".nMain canvas").css({display: "block"})
    @xImg_ = me.loader.getImage("x")
    @oImg_ = me.loader.getImage("o")
    this.loadMainLevel_()

    Meteor.autorun =>
      me.sys.scale = Session.get("scaleFactor")
      # Attach click event listeners
      for column in [0..2]
        for row in [0..2]
          tile = @mainLayer_.layerData[column][row]
          me.input.registerMouseEvent("mouseup", tile, _.bind(@handleClick_, this, tile))

    Meteor.autorun =>
      game = noughts.Games.findOne Session.get("gameId")
      return if not game

      me.game.removeAll()
      this.loadMainLevel_()

      # Redraw all previous moves
      for move in game.moves
        tile = @mainLayer_.layerData[move.column][move.row]
        image = if move.isX then @xImg_ else @oImg_
        sprite = new me.SpriteObject(tile.pos.x, tile.pos.y, image)
        me.game.add(sprite, SPRITE_Z_INDEX)
      me.game.sort()

      winner = noughts.checkForVictory(game)
      if winner
        if winner == Meteor.userId()
          displayNotice("Hooray! You win!")
        else
          displayNotice("Sorry, you lose!")
      else if noughts.isDraw(game)
        displayNotice("The game is over, and it was a draw!")
      else if game.currentPlayer == Meteor.userId()
        displayNotice("It's your turn. Click on a square to make your move.")
      else
        displayNotice("It's your opponent's turn.")

handleNewGameClick = ->
  Meteor.call "newGame", Meteor.userId(), (err, gameId) ->
    if err then throw err
    showInviteDialog (inviteResponse) ->
      return if not inviteResponse
      invitedUser = inviteResponse.to[0]
      requestId = inviteResponse.request
      Meteor.call "inviteOpponent", gameId, invitedUser, requestId, (err) ->
        if err then throw err
        Session.set("gameId", gameId)
        me.state.change(me.state.PLAY)

initialize = ->
  scaleFactor = Session.get("scaleFactor")
  initialized = me.video.init("nMain", 600, 600, true, scaleFactor)
  $(".nMain canvas").css(noughts.centeredBlockCss(scaleFactor, 600, 600))
  if not initialized
    alert("Sorry, your browser doesn't support HTML 5 canvas!")
    return
  me.loader.onload = ->
    noughts.maybeInitialize()
  me.loader.preload(gameResources)

Meteor.startup ->
  $(".nNewGameButton").on("click", handleNewGameClick)
  window.onReady -> initialize()

# Only runs the second time it's called, to ensure both facebook and melon.js
# are loaded
noughts.maybeInitialize = _.after 2, ->
  me.state.set(me.state.PLAY, new PlayScreen())
  requestIds = $.url().param("request_ids")?.split(",")
  fql = "SELECT uid,mutual_friend_count FROM user WHERE uid IN " +
      "( SELECT uid2 FROM friend WHERE uid1=me() )"
  FB.api {method: "fql.query", query: fql}, (result) ->
    noughts.mutualFriends_ = _.sortBy result, (x) ->
      -1 * parseInt(x["mutual_friend_count"], 10)
  FB.api "/me/friends?fields=installed", (result) ->
    installed = _.filter(result.data, (x) -> x.installed)
    noughts.appInstalled_ = _.object(_.pluck(installed, "id"),
        _.pluck(installed, "installed"))
  Meteor.subscribe "myGames", ->
    if not requestIds
      return
    for requestId in requestIds
      fullId = "#{requestId}_#{Meteor.userId()}"
      game = noughts.Games.findOne {requestId: requestId}
      FB.api fullId, "delete", ->
      # TODO(dthurn): do something smarter with multiple request_ids than loading
      # the game for the last one.
    if not game
      throw new Error("Game not found for requestIds: " + requestIds)
    Session.set("gameId", game._id)
    me.state.change(me.state.PLAY)