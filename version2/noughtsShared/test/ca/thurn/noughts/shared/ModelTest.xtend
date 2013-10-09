package ca.thurn.noughts.shared

import java.util.Map
import java.util.HashMap
import ca.thurn.gwt.SharedGWTTestCase

class ModelTest extends SharedGWTTestCase {
	
	String userId
	Model model

  override gwtSetUp() {
  	userId = "userId"
    injectScript("https://cdn.firebase.com/v0/firebase.js", [ |
    	model = new Model(userId)
    ]);
  }

  override getModuleName() {
    if (isServer()) {
      return null
    } else {
      return "ca.thurn.noughts.Shared"
    }
  }

	def newGame(Map args) {
		val map = new HashMap<String, Object>(args)
		if (!map.containsKey("id")) {
			map.put("id", "id")
		}
		return new Game(map)
	}
	
	def void testNewGame() {
		model.addGameAddedCallback([ game |
			assertTrue(game.players.contains(userId))
			assertEquals(Model.X_PLAYER, game.currentPlayerNumber)
			assertTrue(game.lastModified > 0)
			assertFalse(game.gameOver)
			assertEquals(0L, game.actionCount)
		])
		val g = model.newGame(null, null)
		assertTrue(g.players.contains(userId))
		assertEquals(Model.X_PLAYER, g.currentPlayerNumber)
		assertTrue(g.lastModified > 0)
		assertFalse(g.gameOver)
		assertEquals(0L, g.actionCount)
	}
	
	def void testIsCurrentPlayer() {
		val g1 = newGame(#{"gameOver" -> true})
		assertFalse(model.isCurrentPlayer(g1))
		
		val g2 = newGame(#{"currentPlayerNumber" -> 0L, "players" -> #["fooId"]})
		assertFalse(model.isCurrentPlayer(g2))
		
		val g3 = newGame(#{
			"currentPlayerNumber" -> 1L,
			"players" -> #["fooId", "userId"]})
		assertTrue(model.isCurrentPlayer(g3))
		
		val g4 = newGame(#{
			"currentPlayerNumber" -> 0L,
			"players" -> #["fooId", "userId"]})
		assertFalse(model.isCurrentPlayer(g4))
	}
	
	def void testIsPlayer() {
		assertFalse(model.isPlayer(newGame(#{"players" -> #[]})))
		assertFalse(model.isPlayer(newGame(#{"players" -> #["foo"]})))
		assertTrue(model.isPlayer(newGame(#{"players" -> #["foo", "userId"]})))
	}
	
	def void testEnsureIsPlayer() {
		try {
			model.ensureIsPlayer(newGame(#{"players" -> #[]}))
			fail()
		} catch (RuntimeException expected) {}
	}
	
	def void testEnsureIsCurrentPlayer() {
		try {
			model.ensureIsCurrentPlayer(newGame(#{"players" -> #[], "currentPlayerNumber" -> 0L}))
			fail()
		} catch (RuntimeException expected) {}
	}

}