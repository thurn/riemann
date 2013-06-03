###
# To the extent possible under law, the author(s) have dedicated all copyright
# and related and neighboring rights to this software to the public domain
# worldwide. This software is distributed without any warranty. You should have
# received a copy of the CC0 Public Domain Dedication along with this software.
# If not, see <http://creativecommons.org/publicdomain/zero/1.0/>.
###

# Project Riemann web client

# Array of game assets in melonjs format
gameResources = [
  {name: "square", type: "image", src: "/tilemaps/square.jpg"},
  {name: "x", type: "image", src: "/images/x.png"},
  {name: "o", type: "image", src: "/images/o.png"},
  {name: "tilemap", type: "tmx", src: "/tilemaps/game.tmx"}
]

# The Z-Index to add new sprites at
SPRITE_Z_INDEX = 2

# Pops up an alert to the user saying that an error has occurred. Should be used
# for un-recoverable errors.
displayError = (msg) ->
  alert("ERROR: " + msg)
  throw new Error(msg)

# Returns a list of the user IDs of the current user's Facebook friends, sorted
# first by whether or not they have the application installed and then by mutual
# friend count.
getSuggestedFriends = ->
  return [] unless noughts.mutualFriends_ and noughts.appInstalled_
  installed = _.filter(noughts.mutualFriends_, (x) -> noughts.appInstalled_[x.uid])
  notInstalled = _.filter(noughts.mutualFriends_, (x) ->
      not noughts.appInstalled_[x.uid])
  return _.pluck(installed.concat(notInstalled), "uid")

# Displays the Facebook friend-picker invite dialog to let the user select an
# opponent.
showFacebookInviteDialog = (inviteCallback) ->
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

# Displays a short informative message to the user.
displayNotice = (msg) -> $(".nNotification").text(msg)

PlayScreen = me.ScreenObject.extend
  # Helper method to get the game's main layer stored in @mainLayer_
  loadMainLayer_: ->
    me.levelDirector.loadLevel("tilemap")
    @mainLayer_ = me.game.currentLevel.getLayerByName("mainLayer")

  # Called whenever the game state changes to me.state.PLAY, initializes the
  # game and hooks up the appropriate game click event handlers.
  onResetEvent: () ->
    $(".nIdNewGame").remove()
    $(".nMain canvas").css({display: "block"})
    @xImg_ = me.loader.getImage("x")
    @oImg_ = me.loader.getImage("o")
    this.loadMainLayer_()
    me.input.registerMouseEvent "mouseup", me.game.viewport, (event) =>
      touch = me.input.touches[0]
      tile = @mainLayer_.getTile(touch.x, touch.y)
      gameId = Session.get("gameId")
      Meteor.call("performMoveIfLegal", gameId, tile.col, tile.row)

    Meteor.autorun =>
      game = noughts.Games.findOne Session.get("gameId")
      return if not game
      me.game.removeAll()
      this.loadMainLayer_()

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
      else if game[game.currentPlayer] == Meteor.userId()
        displayNotice("It's your turn. Select a square to make your move.")
      else
        displayNotice("") # Clear any previous note

# Handles a click on the "new game" button by popping up an invite dialog
handleNewGameClick = ->
  Meteor.call "newGame", (err, gameId) ->
    if err then throw err
    if Session.get("useFacebook")
      showFacebookInviteDialog (inviteResponse) ->
        return if not inviteResponse
        invitedUser = inviteResponse.to[0]
        requestId = inviteResponse.request
        Meteor.call("facebookInviteOpponent", gameId, invitedUser,
            requestId, (err) ->
          if err then throw err
          Session.set("gameId", gameId)
          me.state.change(me.state.PLAY))
    else
      # TODO(dthurn): Display regular invite dialog
      Session.set("gameId", gameId)
      $(".nNewGameModal").modal()
      #me.state.change(me.state.PLAY)

# Initializer to be called after the DOM ready even to set up MelonJS.
initialize = ->
  scaleFactor = Session.get("scaleFactor")
  initialized = me.video.init("nMain", 600, 600, true, scaleFactor)
  if not initialized
    displayError("Sorry, your browser doesn't support HTML 5 canvas!")
    return
  me.loader.onload = maybeInitialize
  me.loader.preload(gameResources)

# Functions to run as soon as possible on startup. Hooks up event listeners
# and sets up for melonJs loading.
Meteor.startup ->
  $(".nNewGameButton").on("click", handleNewGameClick)
  window.onReady -> initialize()

# Callback for when the user's games are retrieved from the server. Sets up
# some reactive functions and handles facebook ?request_ids params
onSubscribe = ->
  $(".nLoading").css({display: "none"})

  # Update the URL when the game ID changes
  Meteor.autorun ->
    gameId = Session.get("gameId")
    if gameId then window.history.pushState({}, "", "?game_id=#{gameId}")

  # Update game scale when scaleFactor changes
  Meteor.autorun ->
    scaleFactor = Session.get("scaleFactor")
    if scaleFactor then me.video.updateDisplaySize(scaleFactor, scaleFactor)

  requestIds = $.url().param("request_ids")?.split(",")
  if requestIds
    for requestId in requestIds
      fullId = "#{requestId}_#{Meteor.userId()}"
      game = noughts.Games.findOne {requestId: requestId}
      FB.api(fullId, "delete", ->)
      # TODO(dthurn): do something smarter with multiple request_ids than loading
      # the game for the last one.
    displayError("Game not found for requestIds: " + requestIds) unless game
    Session.set("gameId", game._id)
    return me.state.change(me.state.PLAY)

  $(".nNewGamePromo").css({display: "block"})

Template.gameUrl.gameId = -> Session.get("gameId")

# Only runs the second time it's called, to ensure both facebook and melon.js
# are loaded. Kicks off Meteor subscriptions and makes some exploratory Facebook
# API calls.
maybeInitialize = _.after 2, ->
  me.state.set(me.state.PLAY, new PlayScreen())
  if Session.get("useFacebook")
    # Kick off some fetches now for friend ranking data to use later in the
    # invite dialog
    fql = "SELECT uid,mutual_friend_count FROM user WHERE uid IN " +
        "( SELECT uid2 FROM friend WHERE uid1=me() )"
    FB.api {method: "fql.query", query: fql}, (result) ->
      noughts.mutualFriends_ = _.sortBy result, (x) ->
        -1 * parseInt(x["mutual_friend_count"], 10)
    FB.api "/me/friends?fields=installed", (result) ->
      installed = _.filter(result.data, (x) -> x.installed)
      noughts.appInstalled_ = _.object(_.pluck(installed, "id"),
          _.pluck(installed, "installed"))
  Meteor.subscribe("myGames", onSubscribe)

# If the URL includes a request to become a specific player within the game,
# returns the identifying string and strips the ?player parameter out of the
# URL, returning a falsey value if no player was requested.
getRequestedPlayer = ->
  requestedPlayer = $.url().param("player")
  if requestedPlayer
    if requestedPlayer != "x" and requestedPlayer != "o"
      displayError("Invalid requested player!")

    # We take the '?player=' param out of the URL to prevent somebody from
    # accidentally taking over your role when sent a link
    newUrl = "/"
    firstIteration = true
    for key,value of $.url().param()
      if key == "player"
        continue
      separator = if firstIteration then "?" else "&"
      firstIteration = false
      newUrl += "#{separator}#{key}=#{value}"
    window.history.replaceState("", {}, newUrl)
  requestedPlayer

# Sets the current player as the player 'requestedPlayer' ("x" or "o") in
# the game with the id gameId, invoking the provided callback when finished.
# If 'requestedPlayer' is falsey, immediately invokes the callback.
setPlayer = (requestedPlayer, gameId, callback) ->
  if requestedPlayer
    isX = requestedPlayer == "x"
    # TODO(dthurn): Consider issuing a warning if there's already a player in
    # the slot you've requested.
    Meteor.call "setPlayerId", gameId, Meteor.userId(), isX, (err) ->
      if err then throw err
      callback()
  else
    # No change requested, just invoke callback
    callback()

# Callback once the user's identity has been established
noughts.afterAuthenticate = ->
  Meteor.startup ->
    requestedPlayer = getRequestedPlayer()
    gameIdParam = $.url().param("game_id")
    if gameIdParam
      Meteor.call "validateGameId", gameIdParam, (err, gameExists) ->
        if err then throw err
        unless gameExists or requestedPlayer
          # Don't display this error if you've requested to join the game
          displayError("You have not been invited to this game")
        Session.set("gameId", gameIdParam)
        setPlayer requestedPlayer, gameIdParam, ->
          me.state.change(me.state.PLAY)
    maybeInitialize()
