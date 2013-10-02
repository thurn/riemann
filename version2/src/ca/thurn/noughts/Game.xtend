package ca.thurn.noughts

import java.util.List
import java.util.Map

class Game {
  /**
   * The game ID
   */
  @Property final private String id

  /**
   * An array of the players in the game, which can be though of as a bimap
   * from Player Number to Player ID. A player who leaves the game will have
   * her entry in this array replaced with null.
   */
   @Property final List<String> players = newArrayList()

  /**
   * A mapping from player IDs to profile information about the player.
   */
   @Property final Map<String, Map<String, String>> profiles = newHashMap()

  /**
   * The number of the player whose turn it is, that is, their index within
   * the players array. Null when the game is not in progress.
   */
   @Property long currentPlayerNumber

  /**
   * ID of action currently being constructed, or null if no action is under
   * construction (or the game is over). Should never polong to a submitted
   * action. Null when the game is not in progress.
   */
   @Property String currentAction

  /**
   * UNIX timestamp of time when game was last modified.
   */
   @Property long lastModified

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
   @Property final List<String> victors = newArrayList()

  /**
   * True if this game has ended.
   */
   @Property boolean gameOver

  /**
   * Number of (submitted) actions so far in this game.
   */
   @Property long actionCount

  /**
   * An array of player IDs who have resigned the game.
   */
   @Property final List<String> resignedPlayers = newArrayList()
   
	new(String gameId) {
		_id = gameId
	}
  
    def currentPlayerId() {
  		players.get(currentPlayerNumber as int)
  	}
  	
  	def serialize() {
  		#{
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
}