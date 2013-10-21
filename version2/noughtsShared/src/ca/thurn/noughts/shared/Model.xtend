package ca.thurn.noughts.shared

import java.util.Map
import com.firebase.client.Firebase
import com.firebase.client.ChildEventListener
import com.firebase.client.DataSnapshot
import java.util.List

class Model implements ChildEventListener {
  val String _userId
  val Firebase _firebase
  @Property val Map<String, Game> games
  @Property val Callbacks<Game> gameCallbacks
  val Map<String, List<Procedures.Procedure1<Game>>> _gameChangeListeners

  private new(String userId) {
    this(userId, new Firebase("http://www.example.com"))
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

  public static val X_PLAYER = 0L
  public static val O_PLAYER = 1L

  def gameRef(String gameId) {
    return _firebase.child("games").child(gameId)
  }

  def gameRef(Game game) {
    return gameRef(game.id)
  }

  def modifyGame(Firebase firebase, Procedures.Procedure1<Game> function) {
    firebase.runTransaction(new TransactionHandler([data|
      val game = new Game(data.value as Map<String, Object>)
      function.apply(game)
      data.value = game.serialize()
    ]))
  }
  
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
  
  /**
   * Partially create a new game with no opponent specified yet, returning the game ID.
   *
   * @param userProfile Optionally, the Facebook profile of the current user.
   * @param opponentProfile Optionally, the Facebook profile of the opponent
   *     for this game.
   * @return The newly created game
   */
  def newGame(Map<String, String> userProfile, Map<String, String> opponentProfile) {
    val ref = _firebase.child("games").push()
    val game = new Game()
    game.id = ref.name
    game.players.add(_userId)
    game.currentPlayerNumber = X_PLAYER
    game.currentActionNumber = null
    game.lastModified = System.currentTimeMillis()
    game.gameOver = false

    if (userProfile != null) {
      game.profiles.put(userProfile.get("facebookId"), userProfile)
    }
    if (opponentProfile != null) {
      game.profiles.put(opponentProfile.get("facebookId"), opponentProfile)
      game.players.add(opponentProfile.get("facebookId"))
    }

    ref.setValue(game.serialize())
    return game
  }
  
  /**
   * Adds the provided command to the current action's command list. If there is
   * no current action, creates one. Any commands beyond the current location in
   * the undo history are deleted.
   *
   * @param game The current game.
   * @param command The command to add.
   */
  def addCommand(Game game, Command command) {
    ensureIsCurrentPlayer(game)
    if (!isLegalCommand(command)) {
      die("Illegal Command: " + command)
    }
    modifyGame(gameRef(game), [newGame|
      val timestamp = System.currentTimeMillis()
      if (game.hasCurrentAction()) {
        newGame.lastModified = timestamp
        val action = newGame.getCurrentAction()
        action.futureCommands.clear()
        action.commands.add(command)
      } else {
        val action = new Action()
        action.player = _userId
        action.playerNumber = game.currentPlayerNumber
        action.submitted = false
        action.gameId = game.id
        action.commands.add(command)
        newGame.actions.add(action)
        newGame.currentActionNumber = newGame.actions.size() - 1L
        newGame.lastModified = timestamp
      }
    ])
  }

  def isLegalCommand(Command command) {
    return true;
  }


  def die(String message) {
    throw new NoughtsException(message)
  }

  /**
     * Returns true if the current user is the current player in the provided
     * game.
     */
  def isCurrentPlayer(Game game) {
    return if (game.gameOver) {
      false
      } else {
        game.currentPlayerId() == _userId
      }
  }

  /**
   * Returns true if the current user is a player in the provided game.
   */
  def isPlayer(Game game) {
    return game.players.contains(_userId)
  }

  /**
   * Ensures the current user is a player in the provided game.
   */
  def ensureIsPlayer(Game game) {
    if (!isPlayer(game)) die("Unauthorized user: " + _userId)
  }

  /**
   * Ensures the current user is the current player in the provided game.
   */
  def ensureIsCurrentPlayer(Game game) {
    if (!isCurrentPlayer(game)) die("Unauthorized user:  + userId")
  }
  
  override onCancelled() {
  }

}
