###
# To the extent possible under law, the author(s) have dedicated all copyright
# and related and neighboring rights to this software to the public domain
# worldwide. This software is distributed without any warranty. You should have
# received a copy of the CC0 Public Domain Dedication along with this software.
# If not, see <http://creativecommons.org/publicdomain/zero/1.0/>.
###

# Project Riemann data model

# The state of a given game is represented by a document in the games
# collection:
#
# Game {
#   _id: (String) Game ID
#   players: ([String]) List of player IDs in this game
#   profiles: (Map<String, Profile>) A mapping from player IDs to profile
#       information about the player, such
#   currentPlayer: (Integer) Index of current player in the player list
#   actions: [String] List of action IDs of the actions in this game.
#   currentAction: (String) ID of action currently being constructed, or null if
#       no action is under construction. Should never point to a submitted
#       action.
#   requestId: (String) Facebook request ID associated with this game
# }
#
# An Action is defined as follows:
#
# Action {
#   _id: (String) Action ID
#   player: (String) Owner player ID
#   gameId: (String) Owning game ID
#   submitted: (Boolean) Whether this Action has been submitted. Submitted
#       actions are visible to all players, un-submitted actions are only
#       visible to their owner.
#   commands: [Command] Chronological list of commands making up this action.
#   futureCommands: [Command] List of commands that have been undone, from
#       oldest to newest, so that the LAST command in this list is the one which
#       will become active with a "redo".
# }
#
# By convention, players[0] is the game initiator and the "x" player, while
# players[1] is the "o" player.
#
# Security:
# There are a few intentionally insecure aspects of the system:
#
# - As a general rule, if you know the Game ID, you may modify the participants
#   in the game however you wish
# - If you know somebody's secret UUID (stored in their cookie), you can
#   impersonate them at will

noughts.Games = new Meteor.Collection("games")
noughts.Actions = new Meteor.Collection("actions")

noughts.BadRequestError = (message) ->
  @error = 500
  @reason = message
  @name = "BadRequestError"
  @message = message || ""
  this
noughts.BadRequestError.prototype = new Meteor.Error()
noughts.BadRequestError.constructor = noughts.BadRequestError

noughts.X_PLAYER = 0
noughts.O_PLAYER = 1

# Translates a message into a BadRequestError.
die = (msg) ->
  debugger
  console.log("ERORR: " + msg)
  throw new noughts.BadRequestError(msg)

# Returns true if the current user is the current player in the provided game.
isCurrentPlayer = (game) ->
  game.currentPlayer? and Meteor.userId() and
      Meteor.userId() == game.players[game.currentPlayer]

# Ensures that the current user is the current player in the provided game.
ensureIsCurrentPlayer = (game) ->
  unless isCurrentPlayer(game)
    die("Unauthorized user: '#{Meteor.userId()}'")

# Returns the game with ID gameId, or throws an exception if it doesn't exist.
getGame = (gameId) ->
  game = noughts.Games.findOne(gameId)
  if game? then game else die("Invalid game ID: '#{gameId}'")

# Returns the action with ID actionID, or throws an exception if it doesn't
# exist.
getAction = (actionId) ->
  action = noughts.Actions.findOne(actionId)
  if action? then action else die("Invalid action ID: '#{actionId}'")

# General methods, which should be simulated on the client before being invoked
# on the server.
Meteor.methods
  # Validate that the user has logged in as the Facebook user with ID
  # "facebookId". On the server, returns a hash of profile information about
  # the facebook user.
  facebookAuthenticate: (facebookId, accessToken) ->
    if Meteor.isServer
      # Only need to validate facebook token on the server
      result = Meteor.http.get "https://graph.facebook.com/me",
          params:
            fields: "id,name,first_name,gender"
            access_token: accessToken
      response = JSON.parse(result.content)
      responseUserId = response["id"]
      unless facebookId and responseUserId and responseUserId == facebookId
        die("Invalid access token!")
      profile =
        facebookId: facebookId
        givenName: response["first_name"]
        fullName: response["name"]
        gender: response["gender"]

    this.setUserId(facebookId)
    if profile? then return profile

  # Logs the user in based on an anonymous user ID.
  anonymousAuthenticate: (uuid) ->
    hash = CryptoJS.SHA3(uuid, {outputLength: 256}).toString()
    this.setUserId(hash)

  # Submits the provided game's current action and swaps the current player.
  # Validates that the current action is a legal one.
  submitCurrentAction: (gameId) ->
    game = getGame(gameId)
    ensureIsCurrentPlayer(game)

    unless noughts.isCurrentActionLegal(gameId)
      die("Illegal action!")

    newPlayerId =
      if game.currentPlayer == noughts.X_PLAYER
        noughts.O_PLAYER
      else
        noughts.X_PLAYER

    noughts.Actions.update game.currentAction,
      $set: {submitted: true}
    noughts.Games.update gameId,
      $set: {currentPlayer: newPlayerId, currentAction: null}

  # Adds the provided command to the current action's command list. If there is
  # no current action, creates one. Any commands beyond the current location in
  # the undo history are deleted.
  addCommand: (gameId, command) ->
    game = getGame(gameId)
    ensureIsCurrentPlayer(game)
    die("Illegal command!") unless noughts.isLegalCommand(gameId, command)
    timestamp = new Date().toISOString()

    if game.currentAction?
      noughts.Games.update gameId,
        $set: {lastModified: timestamp}
      noughts.Actions.update game.currentAction,
        $push: {commands: command}
        $set: {futureCommands: []}
    else # Create a new current action for this game
      actionId = noughts.Actions.insert
        player: this.userId
        submitted: false
        gameId: gameId
        commands: [command]
        futureCommands: []
      noughts.Games.update gameId,
        $set: {currentAction: actionId, lastModified: timestamp}
        $push: {actions: actionId}

  # Un-does the last command in this game's current action.
  undoCommand: (gameId) ->
    game = getGame(gameId)
    ensureIsCurrentPlayer(game)
    action = getAction(game.currentAction)

    if action.commands.length == 0
      die("No previous command to undo!")

    command = _.last(action.commands)

    noughts.Actions.update game.currentAction,
      $push: {futureCommands: command}
      $pop: {commands: 1}

  # Re-does the last command in this game's current action.
  redoCommand: (gameId) ->
    game = getGame(gameId)
    ensureIsCurrentPlayer(game)
    action = getAction(game.currentAction)

    if action.futureCommands.length == 0
      die("No next command to redo!")

    command = _.last(action.futureCommands)

    noughts.Actions.update game.currentAction,
      $push: {commands: command}
      $pop: {futureCommands: 1}

  # Partially create a new game with no opponent specified yet, returning the
  # game ID. The optional "userProfile" parameter should be the profile of the
  # current user.
  newGame: (userProfile) ->
    game =
      players: [this.userId]
      currentPlayer: noughts.X_PLAYER
      actions: []
      profiles: {}
      currentAction: null
      lastModified: new Date().toISOString()
    if userProfile?
      game.profiles[this.userId] = userProfile
    noughts.Games.insert(game)

  # Stores a facebook request ID with a game so that somebody invited via
  # Facebook can later find the game.
  facebookSetRequestId: (gameId, requestId) ->
    game = getGame(gameId)
    ensureIsCurrentPlayer(game)
    die("game is full") if game.players.length >= noughts.Config.maxPlayers
    noughts.Games.update gameId,
      $set: {requestId: requestId}

# Server-only methods (generally, things which won't work on the client because
# the data isn't in scope yet).
if Meteor.isServer
  Meteor.methods
    # Given a string containing a Facebook request ID, return the ID of the game
    # to load for this request ID. Also adds the current player as a participant
    # in the game if they are not already present via addPlayerIfNotPresent. The
    # optional "userProfile" parameter should container a profile for the
    # current user.
    facebookJoinViaRequestId: (requestId, userProfile) ->
      game = noughts.Games.findOne {requestId: requestId}
      die("Game not found for requestId: " + requestId) unless game?
      Meteor.call("addPlayerIfNotPresent", game._id, userProfile)
      return game._id

    # If the current user is not present in game.players (and the game is not
    # full), add her to the player list. The optional "userProfile" parameter
    # should contain a profile for the current user.
    addPlayerIfNotPresent: (gameId, userProfile) ->
      game = getGame(gameId)
      if (game.players.length < noughts.Config.maxPlayers and
          not _.contains(game.players, this.userId))
        update = {$push: {players: this.userId}}
        if userProfile?
          update["$set"] = {}
          update["$set"]["profiles.#{this.userId}"] = userProfile
        noughts.Games.update(gameId, update)

    # Checks that a game exists based on its ID and that the current user is a
    # participant in it.
    validateGameId: (gameId) ->
      noughts.Games.findOne(gameId)

# Returns a 2-dimensional array of *submitted* game actions spatially indexed
# by [column][row], so e.g. table[0][2] is the bottom-left square's action.
makeActionTable = (gameId) ->
  result = [[], [], []]
  noughts.Actions.find({gameId: gameId}).forEach (action) ->
    return unless action.submitted
    for command in action.commands
      result[command.column][command.row] = action
  result

# Checks if somebody has won this game. If they have, returns the winner's
# user ID. Otherwise, returns false.
noughts.checkForVictory = (gameId) ->
  actionTable = makeActionTable(gameId)

  # All possible winning lines in [column, row] format
  victoryLines = [ [[0,0], [1,0], [2,0]], [[0,1], [1,1], [2,1]],
      [[0,2], [1,2], [2,2]], [[0,0], [0,1], [0,2]], [[1,0], [1,1], [1,2]],
      [[2,0], [2,1], [2,2]], [[0,0], [1,1], [2,2]], [[2,0], [1,1], [0,2]] ]

  for line in victoryLines
    action1 = actionTable[line[0][0]][line[0][1]]
    action2 = actionTable[line[1][0]][line[1][1]]
    action3 = actionTable[line[2][0]][line[2][1]]
    continue unless action1? and action2? and action3?
    if action1.player == action2.player and action2.player == action3.player
      return action1.player
  false

# Returns true if this game is a draw, otherwise false.
noughts.isDraw = (gameId) ->
  game = getGame(gameId)
  game.actions.length == 9

# Checks if the provided command could be legally added to the current action.
noughts.isLegalCommand = (gameId, command) ->
  game = getGame(gameId)
  return false unless isCurrentPlayer(game)
  return false if noughts.checkForVictory(gameId) or noughts.isDraw(gameId)
  if game.currentAction?
    action = noughts.Actions.findOne(game.currentAction)
    return false if action.commands.length != 0
  return noughts.isSquareAvailable(gameId, command.column, command.row)

# Returns true if the game's current action would be a legal game action.
# Returns false if you are not the current player or there is no current action.
noughts.isCurrentActionLegal = (gameId) ->
  # TODO(dthurn): Is this still necessary with isLegalCommand?
  game = getGame(gameId)
  return false unless game.currentAction? and isCurrentPlayer(game)
  action = noughts.Actions.findOne(game.currentAction)
  return false if action.commands.length != 1
  command = action.commands[0]
  noughts.isSquareAvailable(gameId, command.column, command.row)

noughts.isSquareAvailable = (gameId, column, row) ->
  return false if column < 0 or row < 0 or column > 2 or row > 2
  actionTable = makeActionTable(gameId)
  not actionTable[column][row]

noughts.canUndo = (gameId) ->
  game = getGame(gameId)
  if game.currentAction? and isCurrentPlayer(game)
    action = noughts.Actions.findOne(game.currentAction)
    action.commands.length > 0
  else
    false

noughts.canRedo = (gameId) ->
  game = getGame(gameId)
  if game.currentAction? and isCurrentPlayer(game)
    action = noughts.Actions.findOne(game.currentAction)
    action.futureCommands.length > 0
  else
    false
