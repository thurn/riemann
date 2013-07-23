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
  PLAY: me.state.PLAY
  INITIAL_PROMO: me.state.USER + 0 # Initial game description state
  NEW_GAME_MENU: me.state.USER + 1 # Game state for showing new game menu
  FACEBOOK_INVITE: me.state.USER + 2 # Game state for showing new game menu

# Changes the current game state to 'newState'. The optional "urlBehavior"
# parameter shoud be a noughts.state.UrlBehavior, and the browser URL will be
# modified accordingly. The default urlBehavior is
# noughts.state.UrlBehavior.PUSH_URL.
noughts.state.changeState = (newState, urlBehavior) ->
  # TODO(dthurn): Handle a "cancle button" type of state transition which
  # takes the current state out of history.
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
  # TODO(dthurn): No point in doing this if we're inside the Facebook iframe
  if urlBehavior == noughts.state.UrlBehavior.PUSH_URL
    window.history.pushState({}, "", path)
  # state.UrlBehavior.PRESERVE_URL is a no-op.

# Navigates back in the browser history, but throws an error if the navigation
# would take you off-site.
noughts.state.back = ->
  unless noughts.state.hasPreviousState()
    displayError("Tried to invoke state.back() with no more states available")
  # TODO(dthurn): Make this work inside the Facebook iframe.
  window.history.back()

# Pops up an alert to the user saying that an error has occurred. Should be used
# for un-recoverable errors.
displayError = (msg) ->
  debugger
  alert("ERROR: " + msg)
  throw new Error(msg)

facebookInviteCallback = (inviteResponse) ->
  return unless inviteResponse?
  Meteor.call "newGame", Session.get("facebookProfile"), (err, gameId) ->
    invitedUser = inviteResponse.to[0]
    requestId = inviteResponse.request
    Meteor.call("facebookSetRequestId", gameId, requestId, (err) =>
      if err? then throw err
      Session.set("gameId", gameId)
      noughts.state.changeState(noughts.state.PLAY))

# Will be resolved with a list of the user IDs of the current user's Facebook
# friends, sorted first by whether or not they have the application installed
# and then by mutual friend count. cacheSuggestedFriends() must be called to
# get the results.
handleSendFacebookInviteClick = (e) ->
  values = $(".nFacebookFriendSelect").select2("val")
  die("expected a single value") if values.length != 1
  # Safe to turn scaling back on now:
  Session.set("disableScaling", false)
  FB.ui
    method: "apprequests",
    title: "Invite opponent",
    to: values[0]
    message: "Want to play some Noughts?", facebookInviteCallback

# Kicks off fetches to resolve suggestedFriendsDeferred. Can be safely called
# multiple times without duplicating fetches.
buildSuggestedFriends = _.once ->
  mutualFriendsDeferred = $.Deferred()
  appInstallersDeferred = $.Deferred()
  suggestedFriendsDeferred = $.Deferred()

  fql = "SELECT uid,mutual_friend_count,name FROM user WHERE uid IN " +
      "( SELECT uid2 FROM friend WHERE uid1=me() )"
  FB.api {method: "fql.query", query: fql}, (result) ->
    sortedList = _.sortBy result, (x) ->
      -1 * parseInt(x["mutual_friend_count"], 10)
    mutualFriendsDeferred.resolve(sortedList)
  FB.api "/me/friends?fields=installed", (result) ->
    installed = _.filter(result.data, (x) -> x.installed)
    installedMap = _.object(_.pluck(installed, "id"),
        _.pluck(installed, "installed"))
    appInstallersDeferred.resolve(installedMap)
  promise = $.when(mutualFriendsDeferred, appInstallersDeferred)
  promise.done (mutualFriends, appInstallers) ->
    installed = _.filter(mutualFriends, (x) -> appInstallers[x.uid])
    notInstalled = _.filter(mutualFriends, (x) ->
        not appInstallers[x.uid])
    suggestedFriends = installed.concat(notInstalled)
    $(".nFacebookInviteMenu").html(
        Template.facebookInviteMenu({suggestedFriends: suggestedFriends}))
    $(".nSmallFacebookInviteButton").on("click", handleSendFacebookInviteClick)
    $(".nFacebookInviteCancelButton").on "click", ->
        noughts.state.changeState(noughts.state.NEW_GAME_MENU)
    $(".nFacebookFriendSelect").on "change", (e) ->
      setElementEnabled($(".nSmallFacebookInviteButton"), e.val.length > 0)
    $(".nFacebookFriendSelect").select2
      allowClear: true
      placeholder: "Enter opponent's name"
      formatResult: (option) ->
        Template.facebookFriend({name: option.text, uid: option.id})
      maximumSelectionSize: 1
      minimumInputLength: 2
      formatSelectionTooBig: (maxInvitees) ->
        people = if maxInvitees == 1 then "person" else "people"
        "You can only invite #{maxInvitees} #{people}"
      formatSelection: (option, container) ->
        container.append(Template.facebookFriend({name: option.text, uid: option.id}))
        null
  null

# If 'enabled' is true, removes the 'disabled' attribute on the provided
# (jquery-wrapped) element, otherwise adds it.
setElementEnabled = (element, enabled) ->
  if enabled
    element.removeAttr("disabled")
  else
    element.attr("disabled", "disabled")

# Displays the Facebook friend-picker invite dialog to let the user select an
# opponent.
showFacebookInviteDialog = (inviteCallback) ->
  suggestedFriends = getSuggestedFriends()
  if suggestedFriends != []
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

# The "new game" menu
noughts.NewGameMenu = me.ScreenObject.extend
  handleUrlInviteButtonClick_: ->
    Meteor.call "newGame", Session.get("facebookProfile"), (err, gameId) ->
      if err? then throw er
      Session.set("gameId", gameId)
      $(".nBubble").show()
      $(".nDarkenScreen").show()
      $(".nOkUrlCalloutButton").on "click", ->
        $(".nBubble").hide()
        $(".nDarkenScreen").hide()
      noughts.state.changeState(noughts.state.PLAY)

  handleFacebookInviteButtonClick_: ->
      if Session.get("facebookProfile")
        buildSuggestedFriends()
        noughts.state.changeState(noughts.state.FACEBOOK_INVITE)
      else
        FB.login (response) =>
          if response.authResponse
            token = response.authResponse.accessToken
            fbid = response.authResponse.userID
            Meteor.call "facebookAuthenticate", fbid, token, (err, profile) ->
              if err then throw err
              Session.set("facebookProfile", profile)
              buildSuggestedFriends()
              noughts.state.changeState(noughts.state.FACEBOOK_INVITE)
        , {redirect_uri: noughts.appUrl + "facebookInvite"}

  init: ->
    $(".nNewGameMenuCloseButton").on "click", =>
      if noughts.state.hasPreviousState()
        noughts.state.back()
      else
        noughts.state.changeState(noughts.state.INITIAL_PROMO)

    $(".nUrlInviteButton").on("click",
        _.bind(this.handleUrlInviteButtonClick_, this))
    $(".nFacebookInviteButton").on("click",
        _.bind(this.handleFacebookInviteButtonClick_, this))

  onResetEvent: (urlBehavior) ->
    noughts.state.updateUrl("/new", urlBehavior)
    $(".nGame").children().hide()
    $(".nMoveControlsContainer").hide()
    $(".nNewGameMenu").show()
    $(".nGame").css({border: ""})

noughts.FacebookInviteMenu = me.ScreenObject.extend
  onResetEvent: (urlBehavior) ->
    # TODO(dthurn): Log user into facebook here if they aren't yet.
    noughts.state.updateUrl("/facebookInvite", urlBehavior)
    $(".nGame").children().hide()
    $(".nMoveControlsContainer").hide()
    $(".nFacebookInviteMenu").show()
    # Scaling tends to mess up on this screen, especially e.g. when the
    # keyboard pops up on mobile.
    Session.set("disableScaling", true)

# The initial promo for non-players that explains what's going on.
noughts.InitialPromo = me.ScreenObject.extend
  init: ->
    $(".nNewGameButton").on "click", =>
      noughts.state.changeState(noughts.state.NEW_GAME_MENU)

  onResetEvent: (urlBehavior) ->
    noughts.state.updateUrl("/", urlBehavior)
    $(".nGame").children().hide()
    $(".nMoveControlsContainer").hide()
    $(".nGame").css({border: ""})
    $(".nNewGamePromo").show()

# The main screen used for actually playing the game.
noughts.PlayScreen = me.ScreenObject.extend
  init: ->
    $(".nSubmitButton").on "click", ->
      Meteor.call("submitCurrentAction", Session.get("gameId"))
    $(".nUndoButton").on "click", ->
      Meteor.call("undoCommand", Session.get("gameId"))
    $(".nRedoButton").on "click", ->
      Meteor.call("redoCommand", Session.get("gameId"))

  # Enables/disables the three move control buttons (undo, redo, submit) based
  # on whether or not they are currently applicable.
  toggleMoveControls_: (gameId) ->
    setElementEnabled($(".nSubmitButton"), noughts.isCurrentActionLegal(gameId))
    setElementEnabled($(".nUndoButton"), noughts.canUndo(gameId))
    setElementEnabled($(".nRedoButton"), noughts.canRedo(gameId))

  # Helper method to get the game's main layer stored in @mainLayer_
  loadMainLayer_: ->
    me.levelDirector.loadLevel("tilemap")
    @mainLayer_ = me.game.currentLevel.getLayerByName("mainLayer")

  # Invokes via Meteor.autorun while in the PLAY state, reactively updates the
  # UI to show the current game state.
  autorun_: ->
    gameId = Session.get("gameId")
    game = noughts.Games.findOne gameId
    return unless game?
    me.game.removeAll()
    this.loadMainLayer_()

    this.toggleMoveControls_(gameId)

    # Redraw all previous moves
    noughts.Actions.find({gameId: gameId}).forEach (action) =>
      for command in action.commands
        tile = @mainLayer_.layerData[command.column][command.row]
        isX = action.player == game.players[noughts.X_PLAYER]
        image = if isX then @xImg_ else @oImg_
        sprite = new me.SpriteObject(tile.pos.x, tile.pos.y, image)
        me.game.add(sprite, SPRITE_Z_INDEX)
    me.game.sort()

    winner = noughts.checkForVictory(gameId)
    if winner
      if winner == Meteor.userId()
        displayNotice("Hooray! You win!")
      else
        displayNotice("Sorry, you lose!")
    else if noughts.isDraw(gameId)
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
    $(".nMoveControlsContainer").show()
    $(".nGame").css({border: "none"})
    $(".nMain canvas").show()

    @xImg_ = me.loader.getImage("x")
    @oImg_ = me.loader.getImage("o")
    this.loadMainLayer_()

    me.input.registerMouseEvent "mouseup", me.game.viewport, (event) =>
      touch = me.input.touches[0]
      tile = @mainLayer_.getTile(touch.x, touch.y)
      command = {column: tile.col, row: tile.row}
      if noughts.isLegalCommand(gameId, command)
        Meteor.call("addCommand", gameId, command)

    Meteor.subscribe "game", gameId, (err) =>
      if err? then throw err
      Meteor.autorun =>
        this.autorun_()

noughts.melonDeferred = $.Deferred()

# Initializer to be called after the DOM ready even to set up MelonJS.
initialize = ->
  scaleFactor = Session.get("scaleFactor")
  initialized = me.video.init("nIdGame", 600, 600, true, scaleFactor)
  $(".nGame canvas").addClass("nGameCanvas")
  if not initialized
    displayError("Sorry, your browser doesn't support HTML 5 canvas!")
    return
  me.loader.onload = ->
    noughts.melonDeferred.resolve()
  me.loader.preload(gameResources)

# Functions to run as soon as possible on startup. Defines the state map
# and adds a melonjs callback.
Meteor.startup ->
  me.state.set(noughts.state.PLAY, new noughts.PlayScreen())
  me.state.set(noughts.state.NEW_GAME_MENU, new noughts.NewGameMenu())
  me.state.set(noughts.state.INITIAL_PROMO, new noughts.InitialPromo())
  me.state.set(noughts.state.FACEBOOK_INVITE, new noughts.FacebookInviteMenu())
  window.onReady -> initialize()
  $.when(noughts.melonDeferred, noughts.facebookDeferred).done ->
    # Facebook & Melon both loaded
    buildSuggestedFriends() if Session.get("facebookProfile")
    Meteor.subscribe("me", onSubscribe)

# Callback for when the user's games are retrieved from the server. Sets up
# some reactive functions and handles facebook ?request_ids params
onSubscribe = ->
  # Update game scale when scaleFactor changes
  Meteor.autorun ->
    scaleFactor = Session.get("scaleFactor")
    if scaleFactor? then me.video.updateDisplaySize(scaleFactor, scaleFactor)

  setStateFromUrl()
  $(window).on "popstate", ->
    setStateFromUrl()

Template.page.games = ->
  noughts.Games.find({}, {sort: {lastModified: -1}})

Template.page.renderGame = (game, options) ->
  notViewerId = (id) -> id != Meteor.userId()
  opponentId = _.find(game.players, notViewerId)
  opponentProfile = game.profiles[opponentId]
  options.fn
     gameId: game._id
     hasOpponent: opponentId?
     opponentId: opponentId
     opponentHasProfile: opponentProfile?
     opponentProfile: opponentProfile
     opponentPhoto:
         "https://graph.facebook.com/#{opponentId}/picture?type=square"
     lastModified: $.timeago(new Date(game.lastModified))

# Inspects the URL and sets the initial game state accordingly.
setStateFromUrl = ->
  requestIds = $.url().param("request_ids")?.split(",")
  path = $.url().segment(1)
  if requestIds
    for requestId in requestIds
      fullId = "#{requestId}_#{Meteor.userId()}"
      FB.api(fullId, "delete", ->)
    id = _.last(requestIds)
    profile = Session.get("facebookProfile")
    Meteor.call "facebookJoinViaRequestId", id, profile, (err, gameId) ->
      if err? then throw err
      Session.set("gameId", gameId)
      noughts.state.changeState(noughts.state.PLAY)
  else if path == "new"
    noughts.state.changeState(noughts.state.NEW_GAME_MENU,
        noughts.state.UrlBehavior.PRESERVE_URL)
  else if path == "facebookInvite"
    noughts.state.changeState(noughts.state.FACEBOOK_INVITE,
        noughts.state.UrlBehavior.PRESERVE_URL)
  else if path == ""
    # TODO(dthurn): If the user is logged in, display their game list instead
    # of the new game promo
    noughts.state.changeState(noughts.state.INITIAL_PROMO,
        noughts.state.UrlBehavior.PRESERVE_URL)
  else # For simplicity, assume any unrecognized path is a game id
    Meteor.call "validateGameId", path, (err, gameExists) ->
      if err? then throw err
      displayError("Error: Game not found.") unless gameExists
      Session.set("gameId", path)
      profile = Session.get("facebookProfile")
      Meteor.call "addPlayerIfNotPresent", path, profile, (err) ->
        if err? then throw err
        # TODO(dthurn): Show some kind of message if the game is full and the
        # viewer is only a spectator, allowing the viewer to watch or perhaps
        # "clone" the game.
        noughts.state.changeState(noughts.state.PLAY,
            noughts.state.UrlBehavior.PRESERVE_URL)