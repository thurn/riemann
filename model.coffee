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
#   commandsLength: Length of the *effective* command list. The actual list may
#       be longer if it contains commands which have been undone. All commands
#       with an index less than this length should be executed to get the
#       current game state. Performing an "undo" action decrements
#       this index by 1, and a "redo" increases it by 1.
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

# Creates a new action owned by the provided playerId, returning
# the action ID. If the game ID is not yet known, 'null' can be passed.
newAction = (playerId, gameId) ->
  noughts.Actions.insert
    player: playerId
    submitted: false
    gameId: gameId
    commands: []
    commandsLength: 0

Meteor.methods
  # Validate that the user has logged in as the Facebook user with ID "userId".
  facebookAuthenticate: (userId, accessToken) ->
    if Meteor.isServer
      result = Meteor.http.get "https://graph.facebook.com/me",
          params: {fields: "id", access_token: accessToken}
      responseUserId = JSON.parse(result.content)["id"]
      unless userId and responseUserId and responseUserId == userId
        die("Invalid access token!")
      this.setUserId(responseUserId)
    else
      # Don't need to check the user ID on the client
      this.setUserId(userId)

  # Logs the user in based on an anonymous user ID.
  anonymousAuthenticate: (uuid) ->
    this.setUserId(CryptoJS.SHA3(uuid, {outputLength: 256}).toString())

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

    if game.currentAction?
      action = getAction(game.currentAction)
      # Should never happen, but let's check:
      die("Cannot modify submitted action!") if action.submitted

      newCommands = noughts.effectiveCommands(action)
      newCommands.push(command)
      noughts.Actions.update game.currentAction,
        $set: {commands: newCommands, commandsLength: action.commandsLength + 1}
    else # Create a new current action for this game
      actionId = noughts.Actions.insert
        player: this.userId
        submitted: false
        gameId: gameId
        commands: [command]
        commandsLength: 1
      noughts.Games.update gameId,
        $set: {currentAction: actionId}
        $push: {actions: actionId}

  # Un-does the last command in this game's current action.
  undoCommand: (gameId) ->
    game = getGame(gameId)
    ensureIsCurrentPlayer(game)
    action = getAction(game.currentAction)

    if action.commandsLength <= 0
      die("No previous command to undo!")

    noughts.Actions.update game.currentAction,
      $set: {commandsLength: action.commandsLength - 1}

  # Re-does the last command in this game's current action.
  redoCommand: (gameId) ->
    game = getGame(gameId)
    ensureIsCurrentPlayer(game)
    action = getAction(game.currentAction)

    if action.commands.length <= action.commandsLength
      die("No next command to redo!")

    noughts.Actions.update game.currentAction,
      $set: {commandsLength: action.commandsLength + 1}

  # Partially create a new game with no opponent specified yet, returning the
  # game ID.
  newGame: ->
    noughts.Games.insert
      players: [this.userId]
      currentPlayer: noughts.X_PLAYER
      actions: []
      currentAction: null

  # Stores a facebook request ID with a game so that somebody invited via
  # Facebook can later find the game.
  facebookSetRequestId: (gameId, requestId) ->
    game = getGame(gameId)
    ensureIsCurrentPlayer(game)
    die("game is full") if game.players.length >= noughts.Config.maxPlayers
    noughts.Games.update gameId,
      $set: {requestId: requestId}

  # If the current user is not present in game.players (and the game is not
  # full), add her to the player list.
  addPlayerIfNotPresent: (gameId) ->
    if Meteor.isServer
      # Server-only since the game won't be loaded yet on the client
      game = getGame(gameId)
      if (game.players.length < noughts.Config.maxPlayers and
          not _.contains(game.players, this.userId))
        noughts.Games.update gameId,
          $push: {players: this.userId}

  # Checks that a game exists based on its ID and that the current user is a
  # participant in it.
  validateGameId: (gameId) ->
    if Meteor.isServer
      # Server-only since the game won't be loaded yet on the client
      noughts.Games.findOne(gameId)

# Returns a 2-dimensional array of *submitted* game actions spatially indexed
# by [column][row], so e.g. table[0][2] is the bottom-left square's action.
makeActionTable = (gameId) ->
  result = [[], [], []]
  noughts.Actions.find({gameId: gameId}).forEach (action) ->
    return unless action.submitted
    for command in noughts.effectiveCommands(action)
      result[command.column][command.row] = action
  result

# Returns a list of the *effective* commands for this action (those that have
# not been undone).
noughts.effectiveCommands = (action) ->
  action.commands.slice(0, action.commandsLength)

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
    return false if noughts.effectiveCommands(action).length != 0
  return noughts.isSquareAvailable(gameId, command.column, command.row)

# Returns true if the game's current action would be a legal game action.
# Returns false if you are not the current player or there is no current action.
noughts.isCurrentActionLegal = (gameId) ->
  # TODO(dthurn): Is this still necessary with isLegalCommand?
  game = getGame(gameId)
  return false unless game.currentAction? and isCurrentPlayer(game)
  action = noughts.Actions.findOne(game.currentAction)
  return false if noughts.effectiveCommands(action).length != 1
  command = noughts.effectiveCommands(action)[0]
  noughts.isSquareAvailable(gameId, command.column, command.row)

noughts.isSquareAvailable = (gameId, column, row) ->
  return false if column < 0 or row < 0 or column > 2 or row > 2
  actionTable = makeActionTable(gameId)
  not actionTable[column][row]

noughts.canUndo = (gameId) ->
  game = getGame(gameId)
  if game.currentAction? and isCurrentPlayer(game)
    action = noughts.Actions.findOne(game.currentAction)
    action.commandsLength > 0
  else
    false

noughts.canRedo = (gameId) ->
  game = getGame(gameId)
  if game.currentAction? and isCurrentPlayer(game)
    action = noughts.Actions.findOne(game.currentAction)
    return action.commandsLength < action.commands.length
  else
    false
