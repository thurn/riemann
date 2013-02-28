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

checkForVictory = (game) ->
  getMove = (column, row) ->
    _.find(game.moves, (x) -> x.column == column and x.row == row)

  # All possible winning lines in (col, row) format
  victoryLines = [ [[0,0], [1,0], [2,0]], [[0,1], [1,1], [2,1]],
      [[0,2], [1,2], [2,2]], [[0,0], [0,1], [0,2]], [[1,0], [1,1], [1,2]],
      [[2,0], [2,1], [2,2]], [[0,0], [1,1], [2,2]], [[2,0], [1,1], [0,2]] ]

  for line in victoryLines
    move1 = getMove(line[0][0], line[0][1])
    move2 = getMove(line[1][0], line[1][1])
    move3 = getMove(line[2][0], line[2][1])
    continue unless move1? and move2? and move3?
    if move1.isX == move2.isX and move2.isX == move3.isX
      return if move1.isX then game.xPlayer else game.oPlayer
  return false

displayNotice = (msg) -> $(".notice").text(msg)

PlayScreen = me.ScreenObject.extend
  handleClick_: (tile) ->
    game = noughts.Games.findOne {_id: Session.get("gameId")}
    if game and game.currentPlayer == noughts.userId
      spaceTaken = _.any game.moves, (move) ->
        move.column == tile.col and move.row == tile.row
      return if spaceTaken
      isXPlayer = game.currentPlayer == game.xPlayer
      noughts.Games.update {_id: Session.get("gameId")},
        {$set:
          currentPlayer: if isXPlayer then game.oPlayer else game.xPlayer
        $push:
          moves: {column: tile.col, row: tile.row, isX: isXPlayer}}

  onResetEvent: () ->
    $(".noughtsNewGame").css("visibility", "hidden")
    @xImg_ = me.loader.getImage("x")
    @oImg_ = me.loader.getImage("o")

    game = noughts.Games.findOne {_id: Session.get("gameId")}
    opponentId =
      if noughts.userId == game.xPlayer
      then game.oPlayer else game.xPlayer
    FB.api "/#{opponentId}?fields=first_name", (response) ->
      Session.set("opponentName", response.first_name)
    FB.api "/#{noughts.userId}?fields=first_name", (response) ->
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

      winner = checkForVictory(game)
      if winner
        FB.api "/#{winner}?fields=first_name", (response) ->
          Session.set("winnerName", response.first_name)

      if game.moves.length == 9
        Session.set("isDraw", true)

      if Session.get("winnerName")
        displayNotice("The game is over! #{Session.get("winnerName")} has won.")
      else if Session.get("isDraw")
        displayNotice("The game is over, and it was a draw!")
      else if game.currentPlayer == noughts.userId
        displayNotice("It's your turn, #{Session.get("userName")}. Click " +
            "on a square above to make your move.")
      else if game.currentPlayer == opponentId
        displayNotice("It's #{Session.get("opponentName")}'s turn.")

handleNewGameClick = ->
  gameId = noughts.Games.insert
    xPlayer: noughts.userId
    currentPlayer: noughts.userId
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
  me.loader.onload = noughts.runOnSecondCall
  me.loader.preload(gameResources)

Meteor.startup ->
  window.onReady -> onload()

# In order to wait for both Melon and the Facebook SDK, this function
# does nothing when first called and then proceeds on the second call.
numCalls = 0
noughts.runOnSecondCall = ->
  return numCalls++ if numCalls == 0
  debugger
  me.state.set(me.state.PLAY, new PlayScreen())
  me.state.set(me.state.MENU, new TitleScreen())
  requestIds = $.url().param("request_ids")?.split(",")
  if requestIds
    for requestId in requestIds
      fullId = "#{requestId}_#{noughts.userId}"
      game = noughts.Games.findOne {requestId: requestId}
      if not game
        debugger
        throw new Error("Game not found for requestId: " + requestId)
      FB.api fullId, "delete", (response) ->
        if response != true
          throw new Error("Request delete failed: " + response.error.message)
      # TODO(dthurn) do something smarter with multiple request_ids than loading
      # the game for the last one.
      Session.set("gameId", game._id)
      return me.state.change(me.state.PLAY)
  me.state.change(me.state.MENU)