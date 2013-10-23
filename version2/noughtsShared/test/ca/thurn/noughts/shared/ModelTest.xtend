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
    game.currentPlayerNumber = 0
    return game    
  }
  
  def void withTestData(Game game, Procedures.Procedure0 testFn) {
    val gPush = _firebase.child("games").push()
    _testGameId = gPush.name
    game.id = _testGameId
    val gamesRan = new AtomicBoolean(false)
    _firebase.child("games").addChildEventListener(new ChildAddedListener([s1, p1|
      if (gamesRan.getAndSet(true) == false) {
        assertEquals(game, new Game(s1.getValue() as Map<String,Object>))
        testFn.apply()
      }
    ]))
    gPush.setValue(game.serialize())
  }
  
  def newGameWithCurrentAction() {
    return new Game(m(
      "currentPlayerNumber" -> 0,
      "players" -> newArrayList(_userId),
      "actions" -> newArrayList(m(
        "commands" -> newArrayList(m(
          "column" -> 2,
          "row" -> 1
        ))
      )),
      "currentActionNumber" -> 0
    ))    
  }

  def void testNewGame() {
    beginAsyncTestBlock()
    _model.gameCallbacks.childAddedCallbacks.add([g|
      assertTrue(g.players.contains(_userId))
      assertEquals(Model.X_PLAYER, g.currentPlayerNumber)
      assertTrue(g.lastModified > 0L)
      assertTrue(g.localMultiplayer)
      assertFalse(g.gameOver)
      assertEquals(0, g.actions.size())
      finished()
    ])
    val g = _model.newGame(true, null, null)
    assertTrue(g.players.contains(_userId))
    assertEquals(Model.X_PLAYER, g.currentPlayerNumber)
    assertTrue(g.lastModified > 0L)
    assertTrue(g.localMultiplayer)
    assertFalse(g.gameOver)
    assertEquals(0, g.actions.size())
    endAsyncTestBlock()
  }
  
  def act(String player, int column, int row) {
    return new Action(m(
      "player" -> player,
      "submitted" -> true,
      "commands" -> newArrayList(
        m("column" -> column, "row" -> row)
      )
    ))
  }
  
  def void testAddCommandExistingAction() {
    beginAsyncTestBlock()
    val game = new Game()
    game.players.add(_userId)
    game.currentPlayerNumber = 0
    val action = new Action()
    action.gameId = "foo"
    game.actions.add(action)
    game.currentActionNumber = 0
    assertEquals(action, game.getCurrentAction())
    val command = new Command(m("column" -> 2, "row" -> 2))
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

  def void testAddCommandNotCurrentPlayer() {
    assertDies([| _model.addCommand(new Game(
        m("players" -> #["foo", _userId], "currentPlayerNumber" -> 0)
        ), new Command())])    
  }

  def void testAddCommandNewAction() {
    beginAsyncTestBlock()

    val game = new Game(m(
      "players" -> #[_userId],
      "currentPlayerNumber" -> 0
    ))
    val command = new Command(m("column" -> 1, "row" -> 1))
    withTestData(game, [|
      _model.gameCallbacks.childChangedCallbacks.add([newGame |
        assertEquals(_testGameId, newGame.id)
        assertEquals(0, newGame.currentActionNumber)
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
  
  def void testGameChangeListener() {
    beginAsyncTestBlock()
    withTestData(new Game(), [|
      _model.addGameChangeListener(_testGameId, [changedGame|
        assertEquals(123L, changedGame.lastModified)
        finished()
      ])
      _firebase.child("games").child(_testGameId).updateChildren(
        m("lastModified" -> 123L)
      )
    ])
    endAsyncTestBlock()
  }
  
  def void testIsLegalCommand() {
    val command = new Command(m("row" -> 1, "column" -> 1))
    assertFalse(_model.couldSubmitCommand(new Game(m("gameOver" -> true)), command))
    val g1 = newGameWithCurrentAction()
    assertFalse(_model.couldSubmitCommand(g1, command))
    g1.currentActionNumber = null
    g1.actions.get(0).submitted = true
    assertTrue(_model.couldSubmitCommand(g1, command))
    assertFalse(_model.couldSubmitCommand(g1, new Command(m("row" -> 3, "column" -> 1))))
    g1.actions.get(0).commands.get(0).column = 1;
    assertFalse(_model.couldSubmitCommand(g1, command))
  }
  
  def void testCanUndo() {
    val g1 = newGameWithCurrentAction()
    assertTrue(_model.canUndo(g1))
    g1.actions.get(0).commands.clear()
    assertFalse(_model.canUndo(g1))
  }
  
  def void testCanRedo() {
    val g1 = newGameWithCurrentAction()
    assertFalse(_model.canRedo(g1))
    val command = g1.actions.get(0).commands.remove(0)
    g1.actions.get(0).futureCommands.add(command)
    assertTrue(_model.canRedo(g1))
  }
  
  def void testCanSubmit() {
    val g1 = newGameWithCurrentAction()
    assertTrue(_model.canSubmit(g1))
    g1.actions.get(0).commands.clear()
    assertFalse(_model.canSubmit(g1))
    g1.actions.get(0).commands.add(new Command(m("column" -> 0, "row" -> 5)))
    assertFalse(_model.canSubmit(g1))
  }
  
  def void testComputeVictors() {
    var game = new Game()
    game.actions.addAll(#[
      act("x", 0, 0),
      act("o", 0, 1),
      act("x", 0, 2)
    ])
    assertNull(_model.computeVictors(game))
    
    game = new Game()
    game.actions.addAll(#[
      act("x", 0, 0),
      act("x", 0, 1),
      act("x", 0, 2)
    ])
    assertDeepEquals(#["x"], _model.computeVictors(game))
    
    game = new Game()
    game.actions.addAll(#[
      act("x", 0, 0),
      act("x", 1, 1),
      act("x", 2, 2)
    ])
    assertDeepEquals(#["x"], _model.computeVictors(game))
    
    game = new Game()
    game.actions.addAll(#[
      act("x", 0, 2),
      act("o", 1, 1),
      act("x", 1, 2),
      act("o", 0, 1),
      act("x", 2, 2)
    ])
    assertDeepEquals(#["x"], _model.computeVictors(game))
    
    game = new Game()
    game.players.add("x")
    game.players.add("o")
    game.actions.addAll(#[
      act("o", 0, 0),
      act("x", 0, 1),
      act("o", 0, 2),
      act("o", 1, 0),
      act("x", 1, 1),
      act("o", 1, 2),
      act("x", 2, 0),
      act("o", 2, 1),
      act("x", 2, 2)
    ])
    assertDeepEquals(#["x", "o"], _model.computeVictors(game))
  }
  
  def void testSubmitCurrentAction() {
    beginAsyncTestBlock()
    val game = newGameWithCurrentAction()
    withTestData(game, [|
      _model.addGameChangeListener(_testGameId, [newGame|
        assertEquals(1, newGame.currentPlayerNumber)
        assertNull(newGame.currentActionNumber)
        finished()
      ])
      _model.submitCurrentAction(game)
    ])
    endAsyncTestBlock()
  }
  
  def void testSubmitCurrentActionLocalMultiplayer() {
    beginAsyncTestBlock()
    val game = newGameWithCurrentAction()
    game.localMultiplayer = true
    game.players.add(Model.LOCAL_MULTIPLAYER_OPPONENT_ID)
    withTestData(game, [|
      _model.addGameChangeListener(_testGameId, [newGame|
        assertEquals(Model.LOCAL_MULTIPLAYER_OPPONENT_ID, newGame.currentPlayerId)
        finished()
      ])
      _model.submitCurrentAction(game)
    ])
    endAsyncTestBlock()
  }
  
  def void testSubmitCurrentActionGameOver() {
    beginAsyncTestBlock()
    val game = new Game()
    game.players.add(_userId)
    game.players.add("o")
    game.actions.clear()
    game.actions.addAll(#[
      act(_userId, 0, 2),
      act("o", 1, 1),
      act(_userId, 1, 2),
      act("o", 0, 1)
    ])
    val action = new Action()
    action.commands.add(new Command(m("column" -> 2, "row" -> 2)))
    action.player = _userId
    game.actions.add(action)
    game.currentActionNumber = 4
    game.currentPlayerNumber = 0
    withTestData(game, [|
      _model.addGameChangeListener(_testGameId, [newGame|
        assertNull(newGame.currentPlayerNumber)
        assertNull(newGame.currentActionNumber)
        assertDeepEquals(#[_userId], newGame.victors)
        assertTrue(newGame.gameOver)
        finished()
      ])
      _model.submitCurrentAction(game)
    ])
    endAsyncTestBlock()
  }

  def void testUndo() {
    beginAsyncTestBlock()
    val game = newGameWithCurrentAction()
    withTestData(game, [|
      _model.addGameChangeListener(_testGameId, [newGame|
        assertDeepEquals(#[], newGame.currentAction.commands)
        assertDeepEquals(#[new Command(m("column" -> 2, "row" -> 1))],
            newGame.currentAction.futureCommands)
        finished()
      ])
      _model.undoCommand(game)
    ])
    endAsyncTestBlock()
  }
  
  def void testRedo() {
    beginAsyncTestBlock()
    val game = newGameWithCurrentAction()
    game.currentAction.commands.clear()
    val command = new Command(m("column" -> 0, "row" -> 0))
    game.currentAction.futureCommands.add(command)
    withTestData(game, [|
      _model.addGameChangeListener(_testGameId, [newGame|
        assertDeepEquals(#[command], newGame.currentAction.commands)
        assertDeepEquals(#[], newGame.currentAction.futureCommands)
        finished()
      ])
      _model.redoCommand(game)
    ])
    endAsyncTestBlock()
  }

  def void testIsCurrentPlayer() {
    val map = m("gameOver" -> true)
    val g1 = new Game(map)
    assertFalse(_model.isCurrentPlayer(g1))

    val g2 = new Game(m("currentPlayerNumber" -> 0, "players" -> #["fooId"]))
    assertFalse(_model.isCurrentPlayer(g2))

    val g3 = new Game(m(
      "currentPlayerNumber" -> 1,
      "players" -> #["fooId", _userId]))
    assertTrue(_model.isCurrentPlayer(g3))

    val g4 = new Game(m(
      "currentPlayerNumber" -> 0,
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
      _model.ensureIsCurrentPlayer(new Game(#{"players" -> #["foo"], "currentPlayerNumber" -> 0}))
    ])
  }

}