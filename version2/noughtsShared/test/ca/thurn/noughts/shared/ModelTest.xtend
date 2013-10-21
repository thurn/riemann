package ca.thurn.noughts.shared

import ca.thurn.gwt.SharedGWTTestCase
import static ca.thurn.noughts.shared.Util.*;
import com.firebase.client.Firebase
import java.util.concurrent.atomic.AtomicBoolean
import java.util.Map

class ModelTest extends SharedGWTTestCase {

  String _userId
  Model _model
  String _testGameId
  Firebase _firebase

  override gwtSetUp() {
    _userId = "userId"
    injectScript("https://cdn.firebase.com/v0/firebase.js", [ |
      _firebase = new Firebase("http://www.example.com/" + Math.abs(randomInteger()))
      _model = Model.newFromUserId(_userId, _firebase)
    ]);
  }

  override gwtTearDown() {
    _userId = null
    _model = null
    _testGameId = null
    _firebase = null
  }

  override getModuleName() {
    if (isServer()) {
      return null
    } else {
      return "ca.thurn.noughts.Shared"
    }
  }

  def assertDies(Runnable runnable) {
    try {
      runnable.run();
      fail();
    } catch (NoughtsException expected) {}
  }
  
  def makeTestGame() {
    val game = new Game()
    game.players.add(_userId)
    game.currentPlayerNumber = 0L
    return game    
  }
  
  def withTestData(Game game, Procedures.Procedure0 testFn) {
    val gPush = _firebase.child("games").push()
    _testGameId = gPush.name
    game.id = _testGameId
    val gamesRan = new AtomicBoolean(false)
    _firebase.child("games").addChildEventListener(new ChildAddedListener([s1, p1|
      if (gamesRan.getAndSet(true) == false) {
        println("snp " + s1.getValue())
        assertEquals(game, new Game(s1.getValue() as Map<String,Object>))
        testFn.apply()
      }
    ]))
    println("game " + game.serialize())
    gPush.setValue(game.serialize())
  }

  def void testNewGame() {
    beginAsyncTestBlock()
    _model.gameCallbacks.childAddedCallbacks.add([g|
      assertTrue(g.players.contains(_userId))
      assertEquals(Model.X_PLAYER, g.currentPlayerNumber)
      assertTrue(g.lastModified > 0L)
      assertFalse(g.gameOver)
      assertEquals(0, g.actions.size())
      finished()
    ])
    val g = _model.newGame(null, null)
    assertTrue(g.players.contains(_userId))
    assertEquals(Model.X_PLAYER, g.currentPlayerNumber)
    assertTrue(g.lastModified > 0L)
    assertFalse(g.gameOver)
    assertEquals(0L, g.actions.size())
    endAsyncTestBlock()
  }
  
  def testAddCommandExistingAction() {
    beginAsyncTestBlock()
    val game = new Game()
    game.players.add(_userId)
    game.currentPlayerNumber = 0L
    val action = new Action()
    game.actions.add(action)
    game.currentActionNumber = 0L
    assertEquals(action, game.getCurrentAction())
    val command = new Command(m("column" -> 2L, "row" -> 2L))
    withTestData(game, [|
      _model.gameCallbacks.childChangedCallbacks.add([newGame|
        assertTrue(newGame.lastModified > 0)
        val newAction = newGame.getCurrentAction()
        assertEquals(#[], newAction.futureCommands)
        assertEquals(#[command], newAction.commands)
        finished()
      ])
      _model.addCommand(game, command)
    ])
    endAsyncTestBlock()
  }

  def testAddCommandNotCurrentPlayer() {
    assertDies([| _model.addCommand(new Game(
        m("players" -> #["foo", _userId], "currentPlayerNumber" -> 0L)
        ), new Command())])    
  }

  def testAddCommandNewAction() {
    beginAsyncTestBlock()

    val game = new Game(m(
      "players" -> #[_userId],
      "currentPlayerNumber" -> 0L
    ))
    val command = new Command(m("column" -> 1L, "row" -> 1L))
    withTestData(game, [|
      _model.gameCallbacks.childChangedCallbacks.add([newGame |
        assertEquals(_testGameId, newGame.id)
        assertEquals(0L, newGame.currentActionNumber)
        assertTrue(newGame.lastModified > 0)
        val newAction = newGame.getCurrentAction()
        assertEquals(_userId, newAction.player)
        assertFalse(newAction.submitted)
        assertEquals(_testGameId, newAction.gameId)
        assertDeepEquals(#[command], newAction.commands)        
        finished()
      ])
      _model.addCommand(game, command)
    ])
    endAsyncTestBlock()
  }

  def void testIsCurrentPlayer() {
    val map = m("gameOver" -> true)
    val g1 = new Game(map)
    assertFalse(_model.isCurrentPlayer(g1))

    val g2 = new Game(m("currentPlayerNumber" -> 0L, "players" -> #["fooId"]))
    assertFalse(_model.isCurrentPlayer(g2))

    val g3 = new Game(m(
      "currentPlayerNumber" -> 1L,
      "players" -> #["fooId", _userId]))
    assertTrue(_model.isCurrentPlayer(g3))

    val g4 = new Game(m(
      "currentPlayerNumber" -> 0L,
      "players" -> #["fooId", _userId]))
    assertFalse(_model.isCurrentPlayer(g4))
  }

  def void testIsPlayer() {
    assertFalse(_model.isPlayer(new Game(m("players" -> #[]))))
    assertFalse(_model.isPlayer(new Game(m("players" -> #["foo"]))))
    assertTrue(_model.isPlayer(new Game(m("players" -> #["foo", _userId]))))
  }

  def void testEnsureIsPlayer() {
    assertDies([| _model.ensureIsPlayer(new Game(m("players" -> #[])))])
  }

  def void testEnsureIsCurrentPlayer() {
    assertDies([|
      _model.ensureIsCurrentPlayer(new Game(#{"players" -> #["foo"], "currentPlayerNumber" -> 0L}))
    ])
  }

}