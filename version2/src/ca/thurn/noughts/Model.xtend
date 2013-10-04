package ca.thurn.noughts

import java.util.Map
import ca.thurn.firebase.Firebase
import java.util.HashMap
import ca.thurn.firebase.GenericTypeIndicator

class Model {
	val String userId
	val Firebase firebase
	val Map<String, Game> games
	@Property var Functions.Function1<Game, Void> gameAddedCallback;
	
	new(String userId) {
		this.userId = userId
		firebase = new Firebase("http://www.example.com")
		games = new HashMap<String, Game>()
		firebase.child("games").addChildEventListener(
			new ChildAddedListener([snapshot, prevChildName |
				val game = new Game(snapshot.getValue(new MapStringObject()))
				games.put(snapshot.name, game)
				if (gameAddedCallback != null) {
					gameAddedCallback.apply(game)
				}
			]))
	}
	
	static val X_PLAYER = 0L
	static val O_PLAYER = 1L
	
	def newGame(Map<String, String> userProfile, Map<String, String> opponentProfile) {
		val push = firebase.child("games").push()
		val game = new Game(push.name)
		game.players.add(userId)
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
		
		push.setValue(game.serialize())
		return game
	}
	
	def die(String message) {
		throw new RuntimeException(message)
	}
	
	/**
     * Returns true if the current user is the current player in the provided
     * game.
     */
	def isCurrentPlayer(Game game) {
		return if (game.gameOver) {
			false
	    } else {
	    	game.currentPlayerId() == userId
	    }
	}
	
	/**
	 * Returns true if the current user is a player in the provided game.
	 */
	def isPlayer(Game game) {
		return game.players.contains(userId)
	}
	
	/**
	 * Ensures the current user is a player in the provided game.
	 */
	def ensureIsPlayer(Game game) {
		if (!isPlayer(game)) die("Unauthorized user: " + userId)
	}
	
	/**
	 * Ensures the current user is the current player in the provided game.
	 */
	def ensureIsCurrentPlayer(Game game) {
		if (!isCurrentPlayer(game)) die("Unauthorized user:  + userId")
	}
	
}

class MapStringObject extends GenericTypeIndicator<Map<String, Object>> {}