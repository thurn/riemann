###
# To the extent possible under law, the author(s) have dedicated all copyright
# and related and neighboring rights to this software to the public domain
# worldwide. This software is distributed without any warranty. You should have
# received a copy of the CC0 Public Domain Dedication along with this software.
# If not, see <http://creativecommons.org/publicdomain/zero/1.0/>.
###

# Project Riemann client interface

gameResources = [
  {name: "tileset", type: "image", src: "/tilemaps/tileset.jpg"},
  {name: "x", type: "image", src: "/images/x.png"},
  {name: "o", type: "image", src: "/images/o.png"},
  {name: "title", type: "image", src: "/images/title.png"},
  {name: "tilemap", type: "tmx", src: "/tilemaps/tilemap.tmx"}
]

SPRITE_Z_INDEX = 2

showInviteDialog = (inviteCallback) -> FB.ui
  method: "apprequests",
  title: "Select an opponent",
  filters: ["app_non_users", "app_users"],
  max_recipients: 1,
  message: "Want to play some Noughts?", inviteCallback

displayNotice = (msg) -> $(".notice").text(msg)

PlayScreen = me.ScreenObject.extend
  handleClick_: (tile) ->
    Meteor.call("performMoveIfLegal", Session.get("gameId"), tile.col, tile.row)

  loadMainLevel_: ->
    me.levelDirector.loadLevel("tilemap")
    @mainLayer_ = me.game.currentLevel.getLayerByName("mainLayer")

  onResetEvent: () ->
    $(".noughtsNewGame").css("visibility", "hidden")
    @xImg_ = me.loader.getImage("x")
    @oImg_ = me.loader.getImage("o")
    this.loadMainLevel_()

    # Attach click event listeners
    for column in [0..2]
      for row in [0..2]
        tile = @mainLayer_.layerData[column][row]
        me.input.registerMouseEvent("mouseup", tile,
            _.bind(@handleClick_, this, tile))

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

TitleScreen = me.ScreenObject.extend
  init: ->
    @parent(true)
    @title_ = me.loader.getImage("title")
    $(".noughtsNewGame").on("click", handleNewGameClick)

  draw: (context) ->
    $(".noughtsNewGame").css("visibility", "visible")
    context.drawImage(@title_, 0, 0)

initialize = ->
  initialized = me.video.init("jsapp", 384, 384)
  if not initialized
    alert("Sorry, your browser doesn't support HTML 5 canvas!")
    return
  me.loader.onload = ->
    noughts.maybeInitialize()
  me.loader.preload(gameResources)

#Meteor.startup ->
  #window.onReady -> initialize()

# Only runs the second time it's called, to ensure both facebook and melon.js
# are loaded
noughts.maybeInitialize = _.after 2, ->
  me.state.set(me.state.PLAY, new PlayScreen())
  me.state.set(me.state.MENU, new TitleScreen())
  requestIds = $.url().param("request_ids")?.split(",")

  Meteor.subscribe "myGames", ->
    if not requestIds
      return me.state.change(me.state.MENU)
    for requestId in requestIds
      fullId = "#{requestId}_#{Meteor.userId()}"
      game = noughts.Games.findOne {requestId: requestId}
      FB.api fullId, "delete", ->
      # TODO(dthurn) do something smarter with multiple request_ids than loading
      # the game for the last one.
    if not game
      throw new Error("Game not found for requestIds: " + requestIds)
    Session.set("gameId", game._id)
    return me.state.change(me.state.PLAY)