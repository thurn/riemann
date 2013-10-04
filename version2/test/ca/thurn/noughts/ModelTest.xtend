package ca.thurn.noughts

import com.google.gwt.junit.client.GWTTestCase
import com.google.gwt.core.client.ScriptInjector
import java.util.Map
import java.util.HashMap

class ModelTest extends GWTTestCase {
	
	boolean didSetup
	String userId
	Model model

	override void gwtSetUp() throws Exception {
		delayTestFinish(10000);
		if (didSetup == false) {
	    	ScriptInjector
	    		.fromUrl("http://cdn.firebase.com/v0/firebase.js")
	    		.setCallback(new RunnableCallback([ |
	    			didSetup = true
	    			finishTest()
	    		]))
	    		.inject()
		} else {
			finishTest();
		}
		userId = "userId"
		model = new Model(userId)
	}
	
	override getModuleName() {
		return "ca.thurn.Noughts"
	}
	
	def newGame(Map args) {
		val map = new HashMap<String, Object>(args)
		if (!map.containsKey("id")) {
			map.put("id", "id")
		}
		return new Game(map)
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