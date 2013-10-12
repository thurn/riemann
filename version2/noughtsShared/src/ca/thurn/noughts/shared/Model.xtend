package ca.thurn.noughts.shared

import static ca.thurn.noughts.shared.Util.*;

import java.util.Map
import com.firebase.client.Firebase

class Model {
  val String _userId
  val Firebase _firebase
  @Property val Callbacks<Game> games
  @Property val Callbacks<Action> actions

  new(String userId) {
    this(userId, new Firebase("http://www.example.com"))    
  }

  new(String userId, Firebase firebase) {
    _userId = userId
    _firebase = firebase
    _games = new Callbacks<Game>(firebase.child("games"),
      [ map | return new Game(map)]
    )
    _actions = new Callbacks<Action>(firebase.child("actions"),
      [ map | return new Action(map)]
    )
  }

  public static val X_PLAYER = 0L
  public static val O_PLAYER = 1L

  def gameRef(String gameId) {
    return _firebase.child("games").child(gameId)
  }

  def gameRef(Game game) {
    return gameRef(game.id)
  }

  def actionRef(String actionId) {
    return _firebase.child("actions").child(actionId)
  }

  def actionRef(Action action) {
    return actionRef(action.id)
  }
  
  def modifyAction(Firebase firebase, Procedures.Procedure1<Action> function) {
    firebase.runTransaction(new TransactionHandler([data|
      val action = new Action(data.value as Map<String, Object>)
      function.apply(action)
      data.value = action.serialize()
    ]))
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
    game.currentAction = null
    game.lastModified = System.currentTimeMillis()
    game.gameOver = false
    game.actionCount = 0L

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
    val timestamp = System.currentTimeMillis()
    if (game.currentAction != null) {
      gameRef(game).child("lastModified").setValue(timestamp)
      modifyAction(actionRef(game.currentAction), [action|
        action.futureCommands.clear()
        action.commands.add(command)
      ])
    } else {
      val ref = _firebase.child("actions").push()
      val action = new Action()
      action.id = ref.name
      action.player = _userId
      action.playerNumber = game.currentPlayerNumber
      action.submitted = false
      action.gameId = game.id
      action.commands.add(command)
      ref.setValue(action.serialize())
      gameRef(game).updateChildren(m(
        "currentAction" -> ref.name,
        "lastModified" -> timestamp
      ))
    }
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

}
