# Project Riemann client interface

gameResources = [
  {name: "tileset", type: "image", src: "/tilemaps/tileset.jpg"},
  {name: "x", type: "image", src: "/images/x.png"},
  {name: "o", type: "image", src: "/images/o.png"},
  {name: "title", type: "image", src: "/images/title.png"},
  {name: "tilemap", type: "tmx", src: "/tilemaps/tilemap.tmx"}
]

# Tile square size in pixels
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

  onResetEvent: () ->
    $(".noughtsNewGame").css("visibility", "hidden")
    @xImg_ = me.loader.getImage("x")
    @oImg_ = me.loader.getImage("o")

    game = noughts.Games.findOne {_id: Session.get("gameId")}
    opponentId =
      if Meteor.userId() == game.xPlayer
      then game.oPlayer else game.xPlayer
    FB.api "/#{opponentId}?fields=first_name", (response) ->
      Session.set("opponentName", response.first_name)
    FB.api "/#{Meteor.userId()}?fields=first_name", (response) ->
      Session.set("userName", response.first_name)

    Meteor.autorun =>
      game = noughts.Games.findOne {_id: Session.get("gameId")}
      return if not game

      me.game.removeAll()
      me.levelDirector.loadLevel("tilemap")
      @mainLayer_ = me.game.currentLevel.getLayerByName("mainLayer")
      for column in [0..2]
        for row in [0..2]
          tile = @mainLayer_.layerData[column][row]
          me.input.registerMouseEvent("mousedown", tile,
              _.bind(@handleClick_, this, tile))

      for move in game.moves
        tile = @mainLayer_.layerData[move.column][move.row]
        image = if move.isX then @xImg_ else @oImg_
        sprite = new me.SpriteObject(tile.pos.x, tile.pos.y, image)
        me.game.add(sprite, SPRITE_Z_INDEX)
      me.game.sort()

      winner = noughts.checkForVictory(game)
      if winner
        FB.api "/#{winner}?fields=first_name", (response) ->
          Session.set("winnerName", response.first_name)

      if noughts.isDraw(game)
        Session.set("isDraw", true)

      if winner
        if Session.get("winnerName")
          displayNotice("The game is over! #{Session.get("winnerName")} has won.")
        else
          displayNotice("The game is over!")
      else if Session.get("isDraw")
        displayNotice("The game is over, and it was a draw!")
      else if game.currentPlayer == Meteor.userId()
        displayNotice("It's your turn, #{Session.get("userName")}. Click " +
            "on a square above to make your move.")
      else if game.currentPlayer == opponentId
        displayNotice("It's #{Session.get("opponentName")}'s turn.")

handleNewGameClick = ->
  gameId = noughts.Games.insert
    xPlayer: Meteor.userId()
    currentPlayer: Meteor.userId()
    moves: []
  showInviteDialog (inviteResponse) ->
    return if not inviteResponse
    invitedUser = inviteResponse.to[0]
    noughts.Games.update {_id: gameId}
      $set:
        oPlayer: invitedUser
        requestId: inviteResponse.request
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

onload = ->
  initialized = me.video.init("jsapp", 384, 384)
  if not initialized
    alert("Sorry, your browser doesn't support HTML 5 canvas!")
    return
  me.loader.onload = ->
    noughts.melonLoaded = true
    noughts.maybeInitialize()
  me.loader.preload(gameResources)

Meteor.startup ->
  window.onReady -> onload()

noughts.maybeInitialize = ->
  return unless noughts.facebookLoaded and noughts.melonLoaded
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
