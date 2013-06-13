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

SPRITE_Z_INDEX = 2 # The Z-Index to add new sprites at

noughts.state =
  PLAY:          me.state.PLAY
  INITIAL_PROMO: me.state.USER + 0 # Initial game description state
  NEW_GAME_MENU: me.state.USER + 1 # Game state for showing new game menu

# Changes the current game state to 'newState'. The optional "urlBehavior"
# parameter shoud be a noughts.state.UrlBehavior, and the browser URL will be
# modified accordingly. The default urlBehavior is
# noughts.state.UrlBehavior.PUSH_URL.
noughts.state.changeState = (newState, urlBehavior) ->
  urlBehavior ||= noughts.state.UrlBehavior.PUSH_URL
  me.state.change(newState, urlBehavior)

# What a new state should do to the browser URL when entered.
noughts.state.UrlBehavior =
  # Change the current URL and add it to the browser history stack.
  # The default behavior.
  PUSH_URL: 1

  # Keep the existing URL without modifying browser history. Used when e.g.
  # determining the initial state from the URL on page load.
  PRESERVE_URL: 2

# Stores the initial length of the browser history. Used to figure out if
# invoking noguhts.state.back() will take us off-site.
noughts.state.initialHistoryLength = window.history.length

# Returns true if there's a previous state in the state history to go back to.
noughts.state.hasPreviousState = ->
  window.history.length > noughts.state.initialHistoryLength

# Possibly modifies the current browser URL to the to provided path, based on
# the behavior requested in the 'urlBehavior' parameter (a
# noughts.state.UrlBehavior).
noughts.state.updateUrl = (path, urlBehavior) ->
  if urlBehavior == noughts.state.UrlBehavior.PUSH_URL
    window.history.pushState({}, "", path)
  # state.UrlBehavior.PRESERVE_URL is a no-op.

# Navigates back in the browser history, but throws an error if the navigation
# would take you off-site.
noughts.state.back = ->
  unless noughts.state.hasPreviousState()
    displayError("Tried to invoke state.back() with no more states available")
  window.history.back()

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

noughts.NewGameMenu = me.ScreenObject.extend
  init: ->
    $(".nNewGameMenuCloseButton").on "click", ->
      if noughts.state.hasPreviousState()
        noughts.state.back()
      else
        noughts.state.changeState(noughts.state.INITIAL_PROMO)

    $(".nUrlInviteButton").on "click", ->
      Meteor.call "newGame", (err, gameId) ->
        if err then throw err
        Session.set("gameId", gameId)
        $(".nBubble").show()
        $(".nDarkenScreen").show()
        $(".nOkUrlCalloutButton").on "click", ->
          $(".nBubble").hide()
          $(".nDarkenScreen").hide()
        noughts.state.changeState(noughts.state.PLAY)

  onResetEvent: (urlBehavior) ->
    noughts.state.updateUrl("/new", urlBehavior)
    $(".nGame").children().hide()
    $(".nNewGameMenu").show()
    $(".nGame").css({border: ""})

noughts.InitialPromo = me.ScreenObject.extend
  init: ->
    $(".nNewGameButton").on "click", ->
      noughts.state.changeState(noughts.state.NEW_GAME_MENU)

  onResetEvent: (urlBehavior) ->
    noughts.state.updateUrl("/", urlBehavior)
    $(".nGame").children().hide()
    $(".nGame").css({border: ""})
    $(".nNewGamePromo").show()

PlayScreen = me.ScreenObject.extend
  # Helper method to get the game's main layer stored in @mainLayer_
  loadMainLayer_: ->
    me.levelDirector.loadLevel("tilemap")
    @mainLayer_ = me.game.currentLevel.getLayerByName("mainLayer")

  # Invokes via Meteor.autorun while in the PLAY state, reactively updates the
  # UI to show the current game state.
  autorun_: ->
    gameId = Session.get("gameId")
    game = noughts.Games.findOne gameId
    return if not game
    me.game.removeAll()
    this.loadMainLayer_()

    # Redraw all previous moves
    noughts.Actions.find({gameId: gameId}).forEach (action) ->
      command = action.commands[0] # only 1 command per action
      tile = @mainLayer_.layerData[command.column][command.row]
      isX = action.player == game.players[noughts.X_PLAYER]
      image = if isX then @xImg_ else @oImg_
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
    else if game.players[game.currentPlayer] == Meteor.userId()
      displayNotice("It's your turn. Select a square to make your move.")
    else
      displayNotice("") # Clear any previous note

  # Called whenever the game state changes to noughts.state.PLAY, initializes the
  # game and hooks up the appropriate game click event handlers.
  onResetEvent: (urlBehavior) ->
    gameId = Session.get("gameId")
    noughts.state.updateUrl("/#{gameId}", urlBehavior)
    $(".nGame").children().hide()
    $(".nGame").css({border: "none"})
    $(".nMain canvas").show()

    @xImg_ = me.loader.getImage("x")
    @oImg_ = me.loader.getImage("o")
    this.loadMainLayer_()

    me.input.registerMouseEvent "mouseup", me.game.viewport, (event) =>
      touch = me.input.touches[0]
      tile = @mainLayer_.getTile(touch.x, touch.y)
      if noughts.isSquareAvailable(gameId, tile.col, tile.row)
        command = {column: tile.col, row: tile.row}
        Meteor.call "addCommand", gameId, command, (err) ->
          if err then throw err

    Meteor.subscribe "gameActions", gameId, (err) =>
      if err then throw err
      Meteor.autorun =>
        this.autorun_()

# Handles a click on the "new game" button by popping up an invite dialog
handleNewGameClickOld = ->
  Meteor.call "newGame", (err, gameId) ->
    if err then throw err
    if Session.get("useFacebook")
      showFacebookInviteDialog (inviteResponse) ->
        return if not inviteResponse
        invitedUser = inviteResponse.to[0]
        requestId = inviteResponse.request
        Meteor.call("facebookSetRequestId", gameId, requestId, (err) ->
          if err then throw err
          Session.set("gameId", gameId)
          noughts.state.changeState(noughts.state.PLAY))
    else
      # TODO(dthurn): Display regular invite dialog
      Session.set("gameId", gameId)
      $(".nNewGameModal").modal()
      #noughts.state.changeState(noughts.state.PLAY)

# Initializer to be called after the DOM ready even to set up MelonJS.
initialize = ->
  scaleFactor = Session.get("scaleFactor")
  initialized = me.video.init("nIdGame", 600, 600, true, scaleFactor)
  $(".nGame canvas").addClass("nGameCanvas")
  if not initialized
    displayError("Sorry, your browser doesn't support HTML 5 canvas!")
    return
  me.loader.onload = noughts.maybeInitialize
  me.loader.preload(gameResources)

# Functions to run as soon as possible on startup. Defines the state map
# and adds a melonjs callback.
Meteor.startup ->
  me.state.set(noughts.state.PLAY, new PlayScreen())
  me.state.set(noughts.state.NEW_GAME_MENU, new noughts.NewGameMenu())
  me.state.set(noughts.state.INITIAL_PROMO, new noughts.InitialPromo())
  window.onReady -> initialize()

# Callback for when the user's games are retrieved from the server. Sets up
# some reactive functions and handles facebook ?request_ids params
onSubscribe = ->
  # Update game scale when scaleFactor changes
  Meteor.autorun ->
    scaleFactor = Session.get("scaleFactor")
    if scaleFactor then me.video.updateDisplaySize(scaleFactor, scaleFactor)

  setStateFromUrl()
  $(window).on "popstate", ->
    setStateFromUrl()

# Kick off some fetches now for friend ranking data to use later in the
# invite dialog
cacheFacebookData = ->
  fql = "SELECT uid,mutual_friend_count FROM user WHERE uid IN " +
      "( SELECT uid2 FROM friend WHERE uid1=me() )"
  FB.api {method: "fql.query", query: fql}, (result) ->
    noughts.mutualFriends_ = _.sortBy result, (x) ->
      -1 * parseInt(x["mutual_friend_count"], 10)
  FB.api "/me/friends?fields=installed", (result) ->
    installed = _.filter(result.data, (x) -> x.installed)
    noughts.appInstalled_ = _.object(_.pluck(installed, "id"),
        _.pluck(installed, "installed"))

# Only runs the second time it's called, to ensure both facebook and melon.js
# are loaded. Kicks off Meteor subscriptions and makes some exploratory Facebook
# API calls.
noughts.maybeInitialize = _.after 2, ->
  cacheFacebookData() if Session.get("useFacebook")
  Meteor.subscribe("myGames", onSubscribe)

# Inspects the URL and sets the initial game state accordingly.
setStateFromUrl = ->
  requestIds = $.url().param("request_ids")?.split(",")
  path = $.url().segment(1)
  if requestIds
    # Handle a Facebook request_id
    for requestId in requestIds
      fullId = "#{requestId}_#{Meteor.userId()}"
      game = noughts.Games.findOne {requestId: requestId}
      FB.api(fullId, "delete", ->)
      # TODO(dthurn): do something smarter with multiple request_ids than loading
      # the game for the last one.
    displayError("Game not found for requestIds: " + requestIds) unless game
    Session.set("gameId", game._id)
    noughts.state.changeState(noughts.state.PLAY)
  else if path == "new"
    noughts.state.changeState(noughts.state.NEW_GAME_MENU,
        noughts.state.UrlBehavior.PRESERVE_URL)
  else if path == ""
    # TODO(dthurn): If the user is logged in, display their game list instead
    # of the new game promo
    noughts.state.changeState(noughts.state.INITIAL_PROMO,
        noughts.state.UrlBehavior.PRESERVE_URL)
  else # For simplicity, assume any unrecognized path is a game id
    Meteor.call "validateGameId", path, (err, gameExists) ->
      if err then throw err
      displayError("Error: Game not found.") unless gameExists
      Session.set("gameId", path)
      Meteor.call "addPlayerIfNotPresent", path, (err) ->
        if err then throw err
        # TODO(dthurn): Show some kind of message if the game is full and the
        # viewer is only a spectator, allowing the viewer to watch or perhaps
        # "clone" the game.
        noughts.state.changeState(noughts.state.PLAY,
            noughts.state.UrlBehavior.PRESERVE_URL)