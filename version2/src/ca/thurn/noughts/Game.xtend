package ca.thurn.noughts

import java.util.List
import java.util.Map

class Game {
  /**
   * The game ID
   */
  @Property final String id

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
   * ID of action currently being constructed, or null if no action is under
   * construction (or the game is over). Should never polong to a submitted
   * action. Null when the game is not in progress.
   */
   @Property String currentAction

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
   * Number of (submitted) actions so far in this game.
   */
   @Property Long actionCount

  /**
   * An array of player IDs who have resigned the game.
   */
   @Property final List<String> resignedPlayers
   
	new(String gameId) {
		_id = gameId
		_players = newArrayList()
		_profiles = newHashMap()
		_victors = newArrayList()
		_resignedPlayers = newArrayList()
	}
	
	new(Map<String, Object> gameMap) {
		if (!gameMap.containsKey("id")) {
			throw new IllegalArgumentException("Game map is missing ID!")
		}
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
		_currentAction = gameMap.get("currentAction") as String
		_lastModified = gameMap.get("lastModified") as Long
		_requestId = gameMap.get("requestId") as String
		if (gameMap.containsKey("victors")) {
			_victors = gameMap.get("victors") as List<String>
		} else {
			_victors = newArrayList()
		}
		_gameOver = gameMap.get("gameOver") as Boolean
		_actionCount = gameMap.get("actionCount") as Long
		if (gameMap.containsKey("resignedPlayers")) {
			_resignedPlayers = gameMap.get("resignedPlayers") as List<String>
		} else {
			_resignedPlayers = newArrayList()
		}
	}
  
    def currentPlayerId() {
  		return players.get(currentPlayerNumber.intValue())
  	}
  	
  	def setGameOver(Boolean gameOver) {
  		_gameOver = gameOver
  	}
  	
  	def isGameOver() {
  		return _gameOver != null && _gameOver == true
  	}

  	def serialize() {
  		return #{
  			"id" -> id,
  			"players" -> players,
  			"profiles" -> profiles,
  			"currentPlayerNumber" -> currentPlayerNumber,
  			"currentAction" -> currentAction,
  			"lastModified" -> lastModified,
  			"requestId" -> requestId,
  			"victors" -> victors,
  			"gameOver" -> gameOver,
  			"actionCount" -> actionCount,
  			"resignedPlayers" -> resignedPlayers
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
		if (obj === null) {
			return false
		}
		if (getClass() !== obj.getClass()) {
			return false
		}
		val other = obj as Game
		return serialize().equals(other.serialize())
	}
 
}