package ca.thurn.noughts

import java.util.Map
import ca.thurn.firebase.Firebase

class Model {
	final String userId
	final Firebase firebase;
	
	new(String userId) {
		this.userId = userId
		this.firebase = new Firebase("http://www.example.com");
	}
	
	static final val X_PLAYER = 0
	static final val O_PLAYER = 1
	
	def die(String message) {
		throw new RuntimeException(message)
	}
	
	/**
     * Returns true if the current user is the current player in the provided
     * game.
     */
	def isCurrentPlayer(Game game) {
		if (game.gameOver) {
			false
	    } else {
	    	game.currentPlayerId == userId
	    }
	}
	
	/**
	 * Returns true if the current user is a player in the provided game.
	 */
	def isPlayer(Game game) {
		game.players.contains(userId);
	}
	
	/**
	 * Ensures the current user is a player in the provided game.
	 */
	def ensureIsPlayer(Game game) {
		if (!isPlayer(game)) die('''Unauthorized user: "«userId»"''')
	}
	
	/**
	 * Ensures the current user is the current player in the provided game.
	 */
	def ensureIsCurrentPlayer(Game game) {
		if (!isCurrentPlayer(game)) die('''Unauthorized user: "«userId»"''')
	}
	
	def newGame(Map<String, String> userProfile, Map<String, String> opponentProfile) {
		val push = firebase.child("games").push()
		val game = new Game(push.name);
		game.players.add(userId)
		game.currentPlayerNumber = X_PLAYER
		game.currentAction = null
		game.lastModified = System.currentTimeMillis()
		game.gameOver = false
		game.actionCount = 0
		
		if (userProfile != null) {
			game.profiles.put(userProfile.get("facebookId"), userProfile)
		}
		if (opponentProfile != null) {
			game.profiles.put(opponentProfile.get("facebookId"), opponentProfile)
			game.players.add(opponentProfile.get("facebookId"))
		}
		
		push.updateChildren(game.serialize())
		return game
	}
}