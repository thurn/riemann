package ca.thurn.noughts.shared

import java.util.Map
import com.firebase.client.Firebase
import com.firebase.client.ChildEventListener
import com.firebase.client.DataSnapshot
import java.util.List

class Model implements ChildEventListener {
  String _userId
  val Firebase _firebase
  @Property val Map<String, Game> games
  @Property val Callbacks<Game> gameCallbacks
  val Map<String, List<Procedures.Procedure1<Game>>> _gameChangeListeners

  private new(String userId) {
    this(userId, new Firebase("https://gwt.firebaseio.com/"))
  }

  private new(String userId, Firebase firebase) {
    if (userId == null) {
      throw new RuntimeException("UserID was null");
    }
    _userId = userId
    _firebase = firebase
    _games = newHashMap()
    _gameCallbacks = new Callbacks<Game>(firebase.child("games"),
      [ map | return new Game(map)]
    )
    _gameChangeListeners = newHashMap()
    _firebase.child("games").addChildEventListener(this)
  }
  
  def static newFromUserId(String userId) {
    return new Model(userId)
  }
  
  def static newFromUserId(String userId, Firebase firebase) {
    return new Model(userId, firebase)
  }

  public static val X_PLAYER = 0
  public static val O_PLAYER = 1
  public static String LOCAL_MULTIPLAYER_OPPONENT_ID = "LOCAL_MULTIPLAYER_OPPONENT_ID"

  /**
   * Gets a firebase reference to a game by ID.
   */
  def private gameRef(String gameId) {
    return _firebase.child("games").child(gameId)
  }

  /**
   * Gets a firebase reference to a game.
   */
  def private gameRef(Game game) {
    return gameRef(game.id)
  }

  /**
   * Mutate a game via a transaction. The "firebase" parameter must represent a
   * reference to an existing game (such as one returned by "gameRef").
   */
  def private modifyGame(Firebase firebase, Procedures.Procedure1<Game> function) {
    firebase.runTransaction(new TransactionHandler([data|
      val game = new Game(data.value as Map<String, Object>)
      function.apply(game)
      data.value = game.serialize()
    ]))
  }
  
  /**
   * Updates the current user for this model.
   * 
   * @param userId New user id.
   */
  def setUserId(String userId) {
    _userId = userId
  }
  
  /**
   * Adds a listener which will be notified every time a specified gameId is
   * modified.
   * 
   * @param gameId The ID of the game to listen for changes to.
   * @param listener The function to call when changes happen.
   */
  def addGameChangeListener(String gameId, Procedures.Procedure1<Game> listener) {
    if (!_gameChangeListeners.containsKey(gameId)) {
      _gameChangeListeners.put(gameId, newArrayList())
    }
    _gameChangeListeners.get(gameId).add(listener)
  }
  
  def getGame(DataSnapshot snapshot) {
    return new Game(snapshot.getValue() as Map<String, Object>)
  }
  
  override onChildAdded(DataSnapshot snapshot, String prev) {
    val game = getGame(snapshot)
    _games.put(game.id, game)
    if (_gameChangeListeners.containsKey(game.id)) {
      _gameChangeListeners.get(game.id).forEach([listener| listener.apply(game)])
    }
  }
  
  override onChildChanged(DataSnapshot snapshot, String prev) {
    val game = getGame(snapshot)
    _games.put(game.id, game)
    if (_gameChangeListeners.containsKey(game.id)) {
      _gameChangeListeners.get(game.id).forEach([listener| listener.apply(game)])
    }
  }
  
  override onChildMoved(DataSnapshot snapshot, String prev) {
  }
  
  override onChildRemoved(DataSnapshot snapshot) {
    _games.remove(getGame(snapshot).id)
  }
  
  override onCancelled() {
  }
  
  /**
   * Partially create a new game with no opponent specified yet, returning the
   * game ID.
   *
   * @param localMultiplayer Optionally, sets whether the game is a local
   *     multiplayer game.
   * @param userProfile Optionally, the profile of the current user.
   * @param opponentProfile Optionally, the profile of the opponent
   *     for this game.
   * @return The newly created game.
   */
  def newGame(boolean localMultiplayer, Map<String, String> userProfile,
      Map<String, String> opponentProfile) {
    val ref = _firebase.child("games").push()
    val game = new Game()
    game.id = ref.name
    game.players.add(_userId)
    game.localMultiplayer = localMultiplayer 
    if (localMultiplayer) {
      game.players.add(LOCAL_MULTIPLAYER_OPPONENT_ID)
    }
    game.currentPlayerNumber = X_PLAYER
    game.currentActionNumber = null
    game.lastModified = System.currentTimeMillis()
    game.gameOver = false

    if (userProfile != null) {
      if (userProfile.get("id") != _userId) {
        die("Expected user ID in profile to match model user ID")
      }
      game.profiles.put(userProfile.get("id"), userProfile)
    }
    if (opponentProfile != null) {
      game.profiles.put(opponentProfile.get("id"), opponentProfile)
      game.players.add(opponentProfile.get("id"))
    }

    ref.setValue(game.serialize())
    return game
  }
  
  /**
   * Adds the provided command to the current action's command list. If there
   * is no current action, creates one. Any commands beyond the current
   * location in the undo history are deleted.
   *
   * @param game The current game.
   * @param command The command to add.
   */
  def addCommand(Game game, Command command) {
    ensureIsCurrentPlayer(game)
    if (!couldSubmitCommand(game, command)) {
      die("Illegal Command: " + command)
    }
    val userId = _userId
    modifyGame(gameRef(game), [newGame|
      val timestamp = System.currentTimeMillis()
      if (game.hasCurrentAction()) {
        newGame.lastModified = timestamp
        val action = newGame.getCurrentAction()
        action.futureCommands.clear()
        action.gameId = "bar"
        action.commands.add(command)
      } else {
        val action = new Action()
        action.player = userId
        action.playerNumber = game.currentPlayerNumber
        action.submitted = false
        action.gameId = game.id
        action.commands.add(command)
        newGame.actions.add(action)
        newGame.currentActionNumber = newGame.actions.size() - 1
        newGame.lastModified = timestamp
      }
    ])
  }

   /**
    * Checks if a command could legally be played in a game.
    * 
    * @param game Game the command will be added to.
    * @param command The command to check.
    * @return true if this command could be added the current action of this
    *     game. 
    */
  def couldSubmitCommand(Game game, Command command) {
    if (!isCurrentPlayer(game)) {
      return false;
    }
    if (game.hasCurrentAction() && game.getCurrentAction().commands.size() != 0) {
      return false;
    }
    return isLegalCommand(game, command);
  }
  
  /**
   * Checks if the square at (column, row) has been already taken.
   */
  def private isLegalCommand(Game game, Command command) {
    val column = command.column
    val row = command.row 
    if (column < 0 || row < 0 || column > 2 || row > 2) {
      return false;
    }
    return !makeActionTable(game).get(column.intValue).containsKey(row.intValue)
  }

  /** 
   * Returns a 2-dimensional map of *submitted* game actions spatially indexed
   * by [column][row], so e.g. table[0][2] is the bottom-left square's action. 
   */
  def private makeActionTable(Game game) {
    val result = newHashMap(0 -> newHashMap(), 1 -> newHashMap(), 2 -> newHashMap())
    for (action : game.actions) {
      if (action.submitted) {
        for (command : action.commands) {
          val column = command.column.intValue()
          result.get(column).put(command.row.intValue(), action)
        }
      }
    }
    return result
  }

  /**
   * Checks if an undo action is currently possible.
   * 
   * @param game The game to check
   * @return True if a command has been added to the current action of "game"
   *     which can be undone.
   */
  def canUndo(Game game) {
    if (game.hasCurrentAction()) {
      return game.getCurrentAction().commands.size() > 0
    } else {
      return false;
    }
  }
  
  /**
   * Checks if a redo action is currently possible.
   * 
   * @param game The game to check.
   * @return True if a command has been added to the "futureCommands" of the
   *     current action of "game" and thus can be redone.
   */
  def canRedo(Game game) {
    if (game.hasCurrentAction()) {
      return game.getCurrentAction().futureCommands.size() > 0
    } else {
      return false;
    }
  }
  
  /**
   * Checks if the current action can be submitted.
   * 
   * @param game The game to check
   * @return True if the current action of "game" is a legal one which could be
   *     submitted. 
   */
  def canSubmit(Game game) {
    if (!game.hasCurrentAction()) {
      return false
    }
    val action = game.getCurrentAction()
    if (action.commands.size() == 0) {
      return false;
    }
    for (command : action.commands) {
      if (!isLegalCommand(game, command)) {
        return false;
      } 
    }
    return true;    
  }

  /**
  * Submits the provided game's current action, if it is a legal one. If this
  * ends the game: populates the "victors" array and sets the "gameOver"
  * bit. Otherwise, updates the current player.
  * 
  * @param game The game to submit.
  */
  def submitCurrentAction(Game game) {
    ensureIsCurrentPlayer(game)
    if (!canSubmit(game)) {
      die("Illegal action!")
    }
    val isXPlayer = game.currentPlayerNumber == X_PLAYER
    val newPlayerNumber = if (isXPlayer) O_PLAYER else X_PLAYER
    modifyGame(gameRef(game), [newGame|
      newGame.getCurrentAction().submitted = true
      val victors = computeVictors(newGame)
      if (victors == null) {
        newGame.currentPlayerNumber = newPlayerNumber
        newGame.currentActionNumber = null
        if (newGame.localMultiplayer) {
          // Update model with new player number in local multiplayer games
          _userId = newGame.currentPlayerId
        }
      } else {
        // Game over!
        newGame.currentPlayerNumber = null
        newGame.currentActionNumber = null
        newGame.victors.clear()
        newGame.victors.addAll(victors)
        newGame.gameOver = true
      }
    ])
  }
  
  /**
   * Builds the "victors" array for the game. If the game is over, a list will be
   * returned containing the victorious or drawing players (which may be empty to
   * indicate that "nobody wins"). Otherwise, null is returned.
   * 
   * @param game The game to find the victors for
   * @return A list of victors or null if the game is not over.
   */
  def computeVictors(Game game) {
    // Check for win
    val actionTable = makeActionTable(game)
    // All possible winning lines in [column, row] format
    val lines =  #[ #[#[0,0], #[1,0], #[2,0]], #[#[0,1], #[1,1], #[2,1]],
      #[#[0,2], #[1,2], #[2,2]], #[#[0,0], #[0,1], #[0,2]], #[#[1,0], #[1,1], #[1,2]],
      #[#[2,0], #[2,1], #[2,2]], #[#[0,0], #[1,1], #[2,2]], #[#[2,0], #[1,1], #[0,2]] ]
    for (line : lines) {
      val action1 = actionTable.get(line.get(0).get(0))?.get(line.get(0).get(1))
      val action2 = actionTable.get(line.get(1).get(0))?.get(line.get(1).get(1))
      val action3 = actionTable.get(line.get(2).get(0))?.get(line.get(2).get(1))
      if (action1 != null && action2 != null && action3 != null &&
          action1.player == action2.player && action2.player == action3.player) {
        return #[action1.player]
      }
    }
    
    // Check for draw
    if (game.actions.filter([action | action.submitted]).size() == 9) {
      return game.players
    }
    
    // Game is not over.
    return null
  }
  
  def undoCommand(Game game) {
    ensureIsCurrentPlayer(game)
    if (game.currentAction.commands.size() == 0) {
      die("No previous command to undo")
    }
    modifyGame(gameRef(game), [newGame|
      val action = newGame.currentAction
      val command = action.commands.remove(action.commands.size() - 1)
      action.futureCommands.add(command)
    ])
  }
  
  def redoCommand(Game game) {
    ensureIsCurrentPlayer(game)
    if (game.currentAction.futureCommands.size() == 0) {
      die("No previous next command to redo")
    }
    modifyGame(gameRef(game), [newGame|
      val action = newGame.currentAction
      val command = action.futureCommands.remove(action.futureCommands.size() - 1)
      action.commands.add(command)
    ])
  }

  def die(String message) {
    throw new NoughtsException(message)
  }

  /**
   * Returns true if the current user is the current player in the provided
   * game.
   * 
   * @param game The game
   */
  def isCurrentPlayer(Game game) {
    return if (game.gameOver) {
      false
      } else {
        game.getCurrentPlayerId() == _userId
      }
  }

  /**
   * Returns true if the current user is a player in the provided game.
   * 
   * @param game The game
   */
  def isPlayer(Game game) {
    return game.players.contains(_userId)
  }

  /**
   * Ensures the current user is a player in the provided game.
   * 
   * @param game The game
   */
  def ensureIsPlayer(Game game) {
    if (!isPlayer(game)) die("Unauthorized user: " + _userId)
  }

  /**
   * Ensures the current user is the current player in the provided game.
   * 
   * @param game The game
   */
  def ensureIsCurrentPlayer(Game game) {
    if (!isCurrentPlayer(game)) die("Unauthorized user:  + userId")
  }

}
