package ca.thurn.noughts.shared

import ca.thurn.gwt.SharedGWTTestCase
import static ca.thurn.noughts.shared.Util.*;
import com.firebase.client.Firebase
import java.util.concurrent.atomic.AtomicBoolean

class ModelTest extends SharedGWTTestCase {

  String _userId
  Model _model
  String _testGameId
  String _testActionId
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
    _testActionId = null
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
  
  def withTestData(Game game, Action action, boolean makeCurrent, Procedures.Procedure0 testFn) {
    val gPush = _firebase.child("games").push()
    val aPush = _firebase.child("actions").push()
    _testGameId = gPush.name
    _testActionId = aPush.name
    game.id = _testGameId
    if (makeCurrent) {
      game.currentAction = _testActionId
    }
    val gamesRan = new AtomicBoolean(false)
    _firebase.child("games").addChildEventListener(new ChildAddedListener([s1, p1|
      if (gamesRan.getAndSet(true) == false) {
        if (action == null){
          testFn.apply()
          return
        }
        action.id = _testActionId
        action.gameId = _testGameId
        val actionsRan = new AtomicBoolean(false)
        _firebase.child("actions").addChildEventListener(new ChildAddedListener([s2, p2|
          if (actionsRan.getAndSet(true) == false) {
            testFn.apply()
          }
        ]))
        aPush.setValue(action.serialize())
      }
    ]))
    gPush.setValue(game.serialize())
  }

  def void testNewGame() {
    beginAsyncTestBlock()
    _model.games.childAddedCallbacks.add([g|
      assertTrue(g.players.contains(_userId))
      assertEquals(Model.X_PLAYER, g.currentPlayerNumber)
      assertTrue(g.lastModified > 0L)
      assertFalse(g.gameOver)
      assertEquals(0L, g.actionCount)
      finished()
    ])
    val g = _model.newGame(null, null)
    assertTrue(g.players.contains(_userId))
    assertEquals(Model.X_PLAYER, g.currentPlayerNumber)
    assertTrue(g.lastModified > 0L)
    assertFalse(g.gameOver)
    assertEquals(0L, g.actionCount)
    endAsyncTestBlock()
  }
  
  def testAddCommandExistingAction() {
    beginAsyncTestBlock(2)
    val game = new Game()
    game.players.add(_userId)
    game.currentPlayerNumber = 0L
    val command = new Command(m("column" -> 2L, "row" -> 2L))
    val action = new Action()
    withTestData(game, action, true /* makeCurrent */, [|
      _model.actions.childChangedCallbacks.add([newAction|
        assertEquals(#[], newAction.futureCommands)
        assertEquals(#[command], newAction.commands)
        finished()
      ])
      _model.games.childChangedCallbacks.add([newGame|
        assertTrue(newGame.lastModified > 0)
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
    beginAsyncTestBlock(2)

    val game = new Game(m(
      "players" -> #[_userId],
      "currentPlayerNumber" -> 0L
    ))
    val command = new Command(m("column" -> 1L, "row" -> 1L))
    withTestData(game, null, false /* makeCurrent */, [|
      _model.actions.childAddedCallbacks.add([action|
        assertNotNull(action.id)
        assertEquals(_userId, action.player)
        assertFalse(action.submitted)
        assertEquals(_testGameId, action.gameId)
        assertDeepEquals(#[command], action.commands)
        finished()
      ])
      _model.games.childChangedCallbacks.add([g1 |
        assertEquals(_testGameId, g1.id)
        assertNotNull(g1.currentAction)
        assertTrue(g1.lastModified > 0)
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