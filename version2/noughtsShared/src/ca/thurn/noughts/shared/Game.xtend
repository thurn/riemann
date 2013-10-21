package ca.thurn.noughts.shared

import java.util.List
import java.util.Map

class Game {
  /**
   * The game ID
   */
  @Property String id

  /**
   * An array of the players in the game, which can be though of as a bimap
   * from Player Number to Player ID. A player who leaves the game will have
   * her entry in this array replaced with null.
   */
   @Property final List<String> players

  /**
   * A mapping from player IDs to profile information about the player.
   */
   @Property final Map<String, Map<String, String>> profiles

  /**
   * The number of the player whose turn it is, that is, their index within
   * the players array. -1 when the game is not in progress.
   */
   @Property Long currentPlayerNumber

   /**
    * Actions taken in this game, in the order in which they were taken.
    * Potentially includes an unsubmitted action of the current player.
    */
   @Property final List<Action> actions

  /**
   * Index in actions list of action currently being constructed, null when
   * there is no current action.
   */
   @Property Long currentActionNumber

  /**
   * UNIX timestamp of time when game was last modified.
   */
   @Property Long lastModified

  /**
   * Facebook request ID associated with this game.
   */
   @Property String requestId

  /**
   * List of IDs of the players who won this game. In the case of a draw, it
   * should contain all of the drawing players. In the case of a "nobody
   * wins" situation, an empty list should be present. This field cannot be
   * present on a game which is still in progress.
   */
   @Property final List<String> victors

  /**
   * True if this game has ended.
   */
   Boolean _gameOver

  /**
   * An array of player IDs who have resigned the game.
   */
   @Property final List<String> resignedPlayers
   
	new() {
		_players = newArrayList()
		_profiles = newHashMap()
		_actions = newArrayList()
		_victors = newArrayList()
		_resignedPlayers = newArrayList()
	}
	
	new(Map<String, Object> gameMap) {
		_id = gameMap.get("id") as String
		if (gameMap.containsKey("players")) {
			_players = gameMap.get("players") as List<String>
		} else {
			_players = newArrayList()
		}
		if (gameMap.containsKey("profiles")) {
			_profiles = gameMap.get("profiles") as Map<String, Map<String, String>>
		} else {
			_profiles = newHashMap()
		}
		_currentPlayerNumber = gameMap.get("currentPlayerNumber") as Long
		if (gameMap.containsKey("actions")) {
		  val actionList = gameMap.get("actions") as List<Map<String, Object>>
		  _actions = actionList.map([object | new Action(object)])
		} else {
		  _actions = newArrayList()
		}
		_currentActionNumber = gameMap.get("currentActionNumber") as Long
		_lastModified = gameMap.get("lastModified") as Long
		_requestId = gameMap.get("requestId") as String
		if (gameMap.containsKey("victors")) {
			_victors = gameMap.get("victors") as List<String>
		} else {
			_victors = newArrayList()
		}
		_gameOver = gameMap.get("gameOver") as Boolean
		if (gameMap.containsKey("resignedPlayers")) {
			_resignedPlayers = gameMap.get("resignedPlayers") as List<String>
		} else {
			_resignedPlayers = newArrayList()
		}
	}
	
	def static fromMap(Map<String, Object> gameMap) {
	  return new Game(gameMap)
	}
  
  def currentPlayerId() {
		return players.get(_currentPlayerNumber.intValue())
	}
	
	def hasCurrentAction() {
	  return _currentActionNumber != null
	}
	
	def getCurrentAction() {
	  return actions.get(_currentActionNumber.intValue())
	}
	
	def setGameOver(Boolean gameOver) {
		_gameOver = gameOver
	}
	
	def isGameOver() {
		return _gameOver != null && _gameOver == true
	}

	def serialize() {
		return #{
			"id" -> _id,
			"players" -> _players,
			"profiles" -> _profiles,
			"currentPlayerNumber" -> _currentPlayerNumber,
			"actions" -> _actions.map([action | action.serialize()]), 
			"currentActionNumber" -> _currentActionNumber,
			"lastModified" -> _lastModified,
			"requestId" -> _requestId,
			"victors" -> _victors,
			"gameOver" -> _gameOver,
			"resignedPlayers" -> _resignedPlayers
		}
	}
	
	override toString() {
		return "Game: " + serialize().toString()
	}
	
	override hashCode() {
		return serialize().hashCode()
	}
 
	override equals(Object obj) {
		if (this === obj) {
			return true
		}
		if (obj == null) {
			return false
		}
		if (getClass() !== obj.getClass()) {
			return false
		}
		val other = obj as Game
		return serialize().equals(other.serialize())
	}
 
}