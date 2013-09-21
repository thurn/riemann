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

noughts.clickMap = (eventMap) ->
  events = {}
  for key,value of eventMap
    events["#{noughts.util.clickString} #{key}"] = _.debounce(value, 10, true)
  return events

noughts.state =
  PLAY: "PLAY"
  INITIAL_PROMO: "INITIAL_PROMO" # Initial game description state
  NEW_GAME_MENU: "NEW_GAME_MENU" # Game state for showing new game menu
  FACEBOOK_INVITE: "FACEBOOK_INVITE" # Game state for showing new game menu
  LOADING: "LOADING" # Game loading state

noughts.state.stateHistory = []

# Changes the current game state to 'newState'. The optional "urlBehavior"
# parameter shoud be a noughts.state.UrlBehavior, and the browser URL will be
# modified accordingly. The default urlBehavior is noughts.state.UrlBehavior.
# PUSH_URL. Any additional arguments are also past through to the onEnterState
# of the new state.
noughts.state.changeState = (newState, urlBehavior) ->
  urlBehavior ||= noughts.state.UrlBehavior.PUSH_URL
  additionalArguments = _.toArray(arguments).slice(2)
  noughts.state.stateMap[Session.get("state")]?.exitState()

  if urlBehavior != noughts.state.UrlBehavior.PUSH_URL
    # Pop is a no-op on an empty array
    pop = noughts.state.stateHistory.pop()

  noughts.state.stateHistory.push
    state: newState
    additionalArguments: additionalArguments

  # Arguments should be [urlBehavior, args[2], args[3], etc]
  Session.set("state", newState)
  newScreen = noughts.state.stateMap[newState]
  newArgs = [urlBehavior].concat(additionalArguments)
  newScreen.enterState.apply(newScreen, newArgs)

# Navigates back in the state history (and browser history). If the user has
# no previous state, sets the state via loadDefaultState()
noughts.state.back = () ->
  if noughts.state.hasPreviousState()
    if noughts.util.inIframe
      pop = noughts.state.stateHistory.pop()
      target = _.last(noughts.state.stateHistory)
      changeStateArgs = [target.state, noughts.state.UrlBehavior.REPLACE_URL].
          concat(target.additionalArguments)
      noughts.state.changeState.apply(null, changeStateArgs)
    else
      window.history.back()
  else
    loadDefaultState()

# What a new state should do to the browser URL when entered.
noughts.state.UrlBehavior =
  # Change the current URL and add the old one to the browser history stack.
  # The default behavior.
  PUSH_URL: "PUSH_URL"

  # Keep the existing URL without modifying browser history. Used when e.g.
  # determining the initial state from the URL on page load.
  PRESERVE_URL: "PRESERVE_URL"

  # Change the current URL and do not add the previous URL to the history stack.
  # Used to e.g. implement a redirect.
  REPLACE_URL: "REPLACE_URL"

# Returns true if there's a previous state in the state history to go back to.
noughts.state.hasPreviousState = -> return noughts.state.stateHistory.length > 1

# Possibly modifies the current browser URL to the to provided path, based on
# the behavior requested in the 'urlBehavior' parameter (a
# noughts.state.UrlBehavior).
noughts.state.updateUrl = (urlBehavior, path) ->
  # No point in doing this if we're inside an iframe:
  return if noughts.util.inIframe
  if urlBehavior == noughts.state.UrlBehavior.PUSH_URL
    window.history.pushState({}, "", path)
  else if urlBehavior == noughts.state.UrlBehavior.REPLACE_URL
    window.history.replaceState({}, "", path)
  # state.UrlBehavior.PRESERVE_URL is a no-op.

# Displays a modal dialog over the game.
#
# title {string} - The title text of the dialog
# body {string} - The body text of the dialog
# showCloseButton {boolean} - Whether or not to render a close button on the
#     modal dialog. Optional parameter, default is false (do not show).
# actionButtonLabel {string} - Label for the dialog's primary action button.
#     Optional parameter, default is "OK".
# actionButtonClass {string} - Class to apply to the action button, e.g.
#     btn-danger. Optional parameter, default is btn-primary.
# callback {function} - Callback to invoke when the primary action button is
#     clicked. Clicking either button will close the modal. Optional paramter.
noughts.displayModal = (title, body, showCloseButton, actionButtonLabel,
    actionButtonClass, callback) ->
  displayModalFn = ->
    actionButtonLabel ||= "OK"
    actionButtonClass ||= "btn-primary"
    # Remove all previous click handlers
    $(".nGameMessageAction").off(noughts.util.clickEvent)
    $(".nGameMessageHeader").text(title)
    $(".nGameMessageBody").text(body)
    if showCloseButton?
      $(".nGameMessageClose").show()
    else
      $(".nGameMessageClose").hide()
    $(".nGameMessageAction").text(actionButtonLabel)
    $(".nGameMessageAction").removeClass(). # Strip previous classes for safety
        addClass("btn #{actionButtonClass} nGameMessageAction")
    $(".nGameMessage").modal("show")

    $(".nGameMessageAction").one noughts.util.clickEvent, (event) ->
      $(".nGameMessage").modal("hide")
      callback() if callback?

  if noughts.util.isTouch
    # Add a delay on touch platforms to prevent spurious touches from closing
    # the modal.
    setTimeout(displayModalFn, 300)
  else
    displayModalFn()

# Loads the game with the specified ID
playGame = (gameId) ->
  noughts.state.changeState(noughts.state.PLAY,
      noughts.state.UrlBehavior.PUSH_URL, gameId)

# Pops up an alert to the user saying that an error has occurred. Should be used
# for un-recoverable errors.
displayError = (msg) ->
  toastr.error("Error: #{msg}")
  loadDefaultState()
  throw new Error(msg)

facebookInviteCallback = (inviteResponse) ->
  return unless inviteResponse?.to?.length == 1
  opponentId = inviteResponse.to[0]
  options = {params: {fields: "id,name,first_name,gender"}}
  url = "https://graph.facebook.com/#{opponentId}"
  HTTP.get url, options, (err, result) ->
    if err? then throw err
    response = JSON.parse(result.content)
    opponentProfile =
      facebookId: response["id"]
      givenName: response["first_name"]
      fullName: response["name"]
      gender: response["gender"]

    userProfile = Session.get("facebookProfile")
    Meteor.call "newGame", userProfile, opponentProfile, (err, gameId) ->
      invitedUser = inviteResponse.to[0]
      requestId = inviteResponse.request
      Meteor.call "facebookSetRequestId", gameId, requestId, (err) =>
        if err? then throw err
        toastr.success("Invite sent")
        playGame(gameId)

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
    $(".nSmallFacebookInviteButton").on(noughts.util.clickEvent,
        handleSendFacebookInviteClick)
    $(".nFacebookInviteCancelLink").on noughts.util.clickEvent, (e) ->
      e.preventDefault()
      noughts.state.back()
    $(".nFacebookFriendSelect").on "change", (e) ->
      setElementEnabled($(".nSmallFacebookInviteButton"), e.val.length > 0)
    $(".nFacebookFriendSelect").select2
      allowClear: true
      placeholder: "Enter opponent's name"
      formatResult: (option) ->
        Template.facebookFriend({name: option.text, uid: option.id})
      minimumInputLength: if noughts.isMobile() then 2 else 0
      maximumSelectionSize: 1
      formatSelectionTooBig: (maxInvitees) ->
        people = if maxInvitees == 1 then "person" else "people"
        "You can only invite #{maxInvitees} #{people}"
      formatSelection: (option, container) ->
        container.append(Template.facebookFriend({name: option.text, uid: option.id}))
        null
    $(".nFacebookFriendSelect").on "change", (e) ->
      focus = -> $(".nSmallFacebookInviteButton").focus()
      # Need to do this on a timeout because select2 is dumb and is sending
      # its own focus event
      setTimeout(focus, 1)
    if Session.get("state") != noughts.state.FACEBOOK_INVITE
      $("#select2-drop").hide()
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

noughts.Screen = Object.extend
  # Shows a specific screen (a child of nMain) matching the provided selector.
  showScreen: (selector) ->
    $(".nScreen").not(selector).hide()
    $(selector).show()

  enterState: (urlBehavior) ->
    updateUrl = _.partial(noughts.state.updateUrl, urlBehavior)
    @onEnterState.apply(this, [updateUrl].concat(_.rest(arguments)))

  exitState: ->
    if @onExitState?
      @onExitState()

noughts.LoadingScreen = noughts.Screen.extend
  onEnterState: ->
    @showScreen(".nScreenLoading")

# The "new game" menu
noughts.NewGameMenu = noughts.Screen.extend
  init: ->
    events = noughts.clickMap
      ".nNewGameMenuCloseButton": => noughts.state.back()
      ".nUrlInviteButton":
          _.bind(this.handleUrlInviteButtonClick_, this)
      ".nFacebookInviteButton":
          _.bind(this.handleFacebookInviteButtonClick_, this)
    Template.newGameMenu.events(events)

  onEnterState: (updateUrl) ->
    updateUrl("/new")
    @showScreen(".nScreenNewGame")

  handleUrlInviteButtonClick_: ->
    Meteor.call "newGame", Session.get("facebookProfile"), (err, gameId) ->
      if err? then throw er
      $(".nUrlPopover").popover("show")
      setTimeout((-> $(".nUrlPopover").popover("hide")), 4000)
      playGame(gameId)

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

noughts.FacebookInviteMenu = noughts.Screen.extend
  onEnterState: (updateUrl) ->
    # TODO(dthurn): Log user into facebook here if they aren't yet.
    updateUrl("/facebookInvite")
    @showScreen(".nScreenFacebookInvite")
    unless noughts.isMobile()
      $(".nFacebookFriendSelect").select2("open")

    # Scaling tends to mess up on this screen, especially e.g. when the
    # keyboard pops up on mobile.
    # TODO(dthurn): Fix this
    Session.set("disableScaling", true)

# The initial promo for non-players that explains what's going on.
noughts.InitialPromo = noughts.Screen.extend
  init: ->
    events = noughts.clickMap
      ".nNewGameButton": =>
        noughts.state.changeState(noughts.state.NEW_GAME_MENU)
    Template.newGamePromo.events(events)

  onEnterState: (updateUrl) ->
    updateUrl("/")
    @showScreen(".nScreenInitialPromo")

# The main screen used for actually playing the game.
noughts.PlayScreen = noughts.Screen.extend
  init: ->
    undoFn = =>
      $(".nUndoButton").tooltip("hide")
      Meteor.call("undoCommand", Session.get("gameId"))

    redoFn = =>
      $(".nRedoButton").tooltip("hide")
      Meteor.call("redoCommand", Session.get("gameId"))

    submitFn = =>
      Meteor.call "submitCurrentAction", Session.get("gameId"), (err) =>
        if err then throw err
        toastr.success("Move submitted")

    events = noughts.clickMap
      ".nSubmitButton": submitFn
      ".nUndoButton": undoFn
      ".nRedoButton": redoFn
    Template.playScreen.events(events)
    Template.playScreen.rendered = ->
      unless noughts.util.isTouch
        $(".nUndoButton").tooltip({title: "Undo", placement: "bottom"})
        $(".nRedoButton").tooltip({title: "Redo", placement: "bottom"})

  # Called whenever the game state changes to noughts.state.PLAY, initializes the
  # game and hooks up the appropriate game click event handlers.
  onEnterState: (updateUrl, gameId) ->
    updateUrl("/#{gameId}")
    @showScreen(".nScreenPlay")
    Session.set("gameId", gameId)
    $(".nMobileHeader .nMoveControlsContainer").show()

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

  onExitState: ->
    $(".nMobileHeader .nMoveControlsContainer").hide()
    $(".nGameMessage").modal("hide")
    Session.set("gameId", null)

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

  # Invoked via Meteor.autorun while in the PLAY state, reactively updates the
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
        isX = action.playerNumber == noughts.X_PLAYER
        image = if isX then @xImg_ else @oImg_
        sprite = new me.SpriteObject(tile.pos.x, tile.pos.y, image)
        me.game.add(sprite, 2)
    me.game.sort()

    if game.victors?.length == 1
      if game.victors[0] == Meteor.userId()
        displayNotice("Hooray! You win!")
      else
        displayNotice("Sorry, you lose!")
    else if game.victors?.length == 2
      displayNotice("The game is over, and it was a draw!")
    else if game.players[game.currentPlayerNumber] == Meteor.userId()
      displayNotice("It's your turn. Select a square to make your move.")
    else if _.contains(game.players, Meteor.userId())
      displayNotice("It's your opponent's turn.")

noughts.melonDeferred = $.Deferred()

# Initializer to be called after the DOM ready event to set up MelonJS.
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


noughts.state.stateMap = {
  PLAY: new noughts.PlayScreen()
  NEW_GAME_MENU: new noughts.NewGameMenu()
  INITIAL_PROMO: new noughts.InitialPromo()
  FACEBOOK_INVITE: new noughts.FacebookInviteMenu()
  LOADING: new noughts.LoadingScreen()
}

# Functions to run as soon as possible on startup. Switches to the loading state
# and sets up some melonjs initialization.
Meteor.startup ->
  noughts.state.changeState(noughts.state.LOADING,
      noughts.state.UrlBehavior.PRESERVE_URL)

  me.state.set(me.state.PLAY, new me.ScreenObject())
  me.state.change(me.state.PLAY)

  if noughts.isMobile()
    toastPosition = "toast-top-left"
  else
    toastPosition = "toast-top-right"

  toastr.options =
    timeOut: 2000
    positionClass: toastPosition

  window.onReady(-> initialize())
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
    noughts.state.stateHistory.pop()
    setStateFromUrl()

# Builds a string which describes the state of the game, including when it was
# last modified and whether or not it's in-progress or over, who won, etc.
gameStateSummary = (game, lastModified) ->
  # Shorten some longer versions of the "last modified" string
  lastModified = $.timeago(new Date(game.lastModified)).
      replace(/less than a /, "1 ").
      replace(/about /, "")
  if not game.gameOver
    return "Updated " + lastModified
  else if game.victors.length == 2
    return "Draw " + lastModified
  else if game.victors[0] == Meteor.userId()
    return "You won " + lastModified
  opponentId = game.victors[0]
  opponentProfile = game.profiles[opponentId]
  if opponentProfile? and opponentProfile.gender == "male"
    return "He won " + lastModified
  else if opponentProfile? and opponentProfile.gender == "female"
    return "She won " + lastModified
  else
    return "They won " + lastModified

# Returns true if it is the viewer's turn in the provided game. Returns false
# if the game is over.
myTurn = (game) ->
  return false if game.gameOver
  return game.players[game.currentPlayerNumber] == Meteor.userId()

Template.navBody.games = ->
  isCurrentGame = (game) ->
    return false unless Session.get("state") == noughts.state.PLAY
    return game._id == Session.get("gameId")

  getGameInfo = (game) ->
    opponentId = noughts.getOpponentId(game)
    opponentProfile = game.profiles[opponentId]
    isGameCurrent = isCurrentGame(game)

    return $.extend({}, game, {
      gameId: game._id
      isCurrentGame: isGameCurrent
      hasOpponent: opponentId?
      opponentId: opponentId
      opponentHasProfile: opponentProfile?
      opponentProfile: opponentProfile
      opponentPhoto:
          "https://graph.facebook.com/#{opponentId}/picture?type=square"
      gameStateSummary: gameStateSummary(game)
    })

  # Only show games in the game over list that have more than 1 submitted
  # action.
  interestingGameOverGame = (game) ->
    return false unless game.gameOver
    return true if isCurrentGame(game)
    return game.actionCount > 1

  games = noughts.Games.find({}, {sort: {lastModified: -1}}).map(getGameInfo)
  inProgressGames = _.filter(games, (game) -> !game.gameOver)
  gameOverGames = _.filter(games, interestingGameOverGame)
  result = {
    gameOver: gameOverGames
    myTurn: _.filter(inProgressGames, myTurn)
    theirTurn: _.filter(inProgressGames, (game) -> !myTurn(game))
    newGameSelected: Session.get("state") == noughts.state.NEW_GAME_MENU
  }
  return result

# Delay closing the nav to give the user time to process what's happening.
closeNavDelay = ->
  setTimeout((-> noughts.closeNav()), 300)

navBodyEvents = noughts.clickMap
  ".nResignGameButton": (event) ->
    closeNavDelay()
    gameId = $(this).attr("gameId")
    resignCallback = ->
      Meteor.call "resignGame", gameId, (err) ->
        if err then throw err
        toastr.warning("You left the game.")

    noughts.displayModal("Confirm Leaving",
        "Are you sure you want to leave this game?",
        true, # showCloseButton
        "Leave Game",
        "btn-danger",
        resignCallback)

  ".nArchiveGameButton": (event) ->
    gameId = $(this).attr("gameId")
    Meteor.call "archiveGame", gameId, (err) ->
      if err then throw err
      toastr.success("Game deleted")
      if gameId == Session.get("gameId")
        loadDefaultState()

  ".nGameListingBody": (event) ->
    closeNavDelay()
    playGame($(this).attr("gameId"))

  ".nGameListNewGameButton": (event) ->
    closeNavDelay()
    noughts.state.changeState(noughts.state.NEW_GAME_MENU)

navBodyEvents["click a"] = (event) -> event.preventDefault()
Template.navBody.events(navBodyEvents)

Template.navBody.rendered = ->
  unless noughts.util.isTouch
    $(".nResignGameButton").tooltip({title: "Leave Game", placement: "auto"})
    $(".nArchiveGameButton").tooltip({title: "Delete", placement: "auto"})

# Inspects the URL and sets the initial game state accordingly.
setStateFromUrl = () ->
  requestIds = $.url().param("request_ids")?.split(",")
  if requestIds
    for requestId in requestIds
      fullId = "#{requestId}_#{Meteor.userId()}"
      FB.api(fullId, "delete", ->)
    id = _.last(requestIds)
    profile = Session.get("facebookProfile")
    Meteor.call "facebookJoinViaRequestId", id, profile, (err, gameId) ->
      if err? then throw err
      playGame(gameId)
  else
    setStateFromPath($.url().segment(1))

# Sets the initial game state based on the request path (specifically the
# first segment after the domain). Does not handle e.g. ?request_ids=
# parameters.
setStateFromPath = (path) ->
  if path == "new"
    noughts.state.changeState(noughts.state.NEW_GAME_MENU,
        noughts.state.UrlBehavior.PRESERVE_URL)
  else if path == "facebookInvite"
    noughts.state.changeState(noughts.state.FACEBOOK_INVITE,
        noughts.state.UrlBehavior.PRESERVE_URL)
  else if path == ""
    loadDefaultState()
  else # For simplicity, assume any unrecognized path is a game id
    gameId = path
    Meteor.call "validateGameId", gameId, (err, gameExists) ->
      if err? then throw err
      unless gameExists
        displayError("Game not found!")
      profile = Session.get("facebookProfile")
      Meteor.call "addPlayerIfNotPresent", gameId, profile, (err) ->
        if err? then throw err
        # TODO(dthurn): Show some kind of message if the game is full and the
        # viewer is only a spectator, allowing the viewer to watch or perhaps
        # "clone" the game.
        noughts.state.changeState(noughts.state.PLAY,
            noughts.state.UrlBehavior.PRESERVE_URL, gameId)

# Switches to the default state for the game, which is either a game where it's
# the user's turn or the "create a new game" promo screen. Implemented like a
# redirect, so the current URL is always replaced with that of the new screen.
loadDefaultState = ->
  games = noughts.Games.find({}, {sort: {lastModified: -1}}).fetch()
  myTurnGames = _.filter(games, myTurn)
  if myTurnGames.length > 0
    # Load the most recently modified game where it's my turn.
    game = myTurnGames[0]
    # Redirect to the the URL of the most recently modified game.
    noughts.state.changeState(noughts.state.PLAY,
        noughts.state.UrlBehavior.REPLACE_URL, game._id)
  else
    # Show the new game promo
    noughts.state.changeState(noughts.state.INITIAL_PROMO,
        noughts.state.UrlBehavior.REPLACE_URL)
