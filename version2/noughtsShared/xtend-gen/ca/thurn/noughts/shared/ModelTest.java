package ca.thurn.noughts.shared;

import ca.thurn.gwt.SharedGWTTestCase;
import ca.thurn.noughts.shared.Game;
import ca.thurn.noughts.shared.Model;
import com.google.common.collect.Lists;
import com.google.common.collect.Maps;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import junit.framework.TestCase;
import org.eclipse.xtext.xbase.lib.Exceptions;
import org.eclipse.xtext.xbase.lib.Procedures.Procedure1;

@SuppressWarnings("all")
public class ModelTest extends SharedGWTTestCase {
  private String userId;
  
  private Model model;
  
  public void gwtSetUp() {
    this.userId = "userId";
    final Runnable _function = new Runnable() {
      public void run() {
        Model _model = new Model(ModelTest.this.userId);
        ModelTest.this.model = _model;
      }
    };
    this.injectScript("https://cdn.firebase.com/v0/firebase.js", _function);
  }
  
  public String getModuleName() {
    boolean _isServer = this.isServer();
    if (_isServer) {
      return null;
    } else {
      return "ca.thurn.noughts.Shared";
    }
  }
  
  public Game newGame(final Map args) {
    HashMap<String,Object> _hashMap = new HashMap<String, Object>(args);
    final HashMap<String,Object> map = _hashMap;
    boolean _containsKey = map.containsKey("id");
    boolean _not = (!_containsKey);
    if (_not) {
      map.put("id", "id");
    }
    Game _game = new Game(map);
    return _game;
  }
  
  public void testNewGame() {
    final Procedure1<Game> _function = new Procedure1<Game>() {
      public void apply(final Game game) {
        List<String> _players = game.getPlayers();
        boolean _contains = _players.contains(ModelTest.this.userId);
        TestCase.assertTrue(_contains);
        Long _currentPlayerNumber = game.getCurrentPlayerNumber();
        TestCase.assertEquals(Model.X_PLAYER, (_currentPlayerNumber).longValue());
        Long _lastModified = game.getLastModified();
        boolean _greaterThan = ((_lastModified).longValue() > 0);
        TestCase.assertTrue(_greaterThan);
        boolean _isGameOver = game.isGameOver();
        TestCase.assertFalse(_isGameOver);
        Long _actionCount = game.getActionCount();
        TestCase.assertEquals(0L, (_actionCount).longValue());
      }
    };
    this.model.addGameAddedCallback(_function);
    final Game g = this.model.newGame(null, null);
    List<String> _players = g.getPlayers();
    boolean _contains = _players.contains(this.userId);
    TestCase.assertTrue(_contains);
    Long _currentPlayerNumber = g.getCurrentPlayerNumber();
    TestCase.assertEquals(Model.X_PLAYER, (_currentPlayerNumber).longValue());
    Long _lastModified = g.getLastModified();
    boolean _greaterThan = ((_lastModified).longValue() > 0);
    TestCase.assertTrue(_greaterThan);
    boolean _isGameOver = g.isGameOver();
    TestCase.assertFalse(_isGameOver);
    Long _actionCount = g.getActionCount();
    TestCase.assertEquals(0L, (_actionCount).longValue());
  }
  
  public void testIsCurrentPlayer() {
    Map<String,Boolean> _xsetliteral = null;
    Map<String,Boolean> _tempMap = Maps.<String, Boolean>newHashMap();
    _tempMap.put("gameOver", Boolean.valueOf(true));
    _xsetliteral = Collections.<String, Boolean>unmodifiableMap(_tempMap);
    final Game g1 = this.newGame(_xsetliteral);
    boolean _isCurrentPlayer = this.model.isCurrentPlayer(g1);
    TestCase.assertFalse(_isCurrentPlayer);
    Map<String,Object> _xsetliteral_1 = null;
    Map<String,Object> _tempMap_1 = Maps.<String, Object>newHashMap();
    _tempMap_1.put("currentPlayerNumber", Long.valueOf(0L));
    _tempMap_1.put("players", Collections.<String>unmodifiableList(Lists.<String>newArrayList("fooId")));
    _xsetliteral_1 = Collections.<String, Object>unmodifiableMap(_tempMap_1);
    final Game g2 = this.newGame(_xsetliteral_1);
    boolean _isCurrentPlayer_1 = this.model.isCurrentPlayer(g2);
    TestCase.assertFalse(_isCurrentPlayer_1);
    Map<String,Object> _xsetliteral_2 = null;
    Map<String,Object> _tempMap_2 = Maps.<String, Object>newHashMap();
    _tempMap_2.put("currentPlayerNumber", Long.valueOf(1L));
    _tempMap_2.put("players", Collections.<String>unmodifiableList(Lists.<String>newArrayList("fooId", "userId")));
    _xsetliteral_2 = Collections.<String, Object>unmodifiableMap(_tempMap_2);
    final Game g3 = this.newGame(_xsetliteral_2);
    boolean _isCurrentPlayer_2 = this.model.isCurrentPlayer(g3);
    TestCase.assertTrue(_isCurrentPlayer_2);
    Map<String,Object> _xsetliteral_3 = null;
    Map<String,Object> _tempMap_3 = Maps.<String, Object>newHashMap();
    _tempMap_3.put("currentPlayerNumber", Long.valueOf(0L));
    _tempMap_3.put("players", Collections.<String>unmodifiableList(Lists.<String>newArrayList("fooId", "userId")));
    _xsetliteral_3 = Collections.<String, Object>unmodifiableMap(_tempMap_3);
    final Game g4 = this.newGame(_xsetliteral_3);
    boolean _isCurrentPlayer_3 = this.model.isCurrentPlayer(g4);
    TestCase.assertFalse(_isCurrentPlayer_3);
  }
  
  public void testIsPlayer() {
    Map<String,List<Object>> _xsetliteral = null;
    Map<String,List<Object>> _tempMap = Maps.<String, List<Object>>newHashMap();
    _tempMap.put("players", Collections.<Object>unmodifiableList(Lists.<Object>newArrayList()));
    _xsetliteral = Collections.<String, List<Object>>unmodifiableMap(_tempMap);
    Game _newGame = this.newGame(_xsetliteral);
    boolean _isPlayer = this.model.isPlayer(_newGame);
    TestCase.assertFalse(_isPlayer);
    Map<String,List<String>> _xsetliteral_1 = null;
    Map<String,List<String>> _tempMap_1 = Maps.<String, List<String>>newHashMap();
    _tempMap_1.put("players", Collections.<String>unmodifiableList(Lists.<String>newArrayList("foo")));
    _xsetliteral_1 = Collections.<String, List<String>>unmodifiableMap(_tempMap_1);
    Game _newGame_1 = this.newGame(_xsetliteral_1);
    boolean _isPlayer_1 = this.model.isPlayer(_newGame_1);
    TestCase.assertFalse(_isPlayer_1);
    Map<String,List<String>> _xsetliteral_2 = null;
    Map<String,List<String>> _tempMap_2 = Maps.<String, List<String>>newHashMap();
    _tempMap_2.put("players", Collections.<String>unmodifiableList(Lists.<String>newArrayList("foo", "userId")));
    _xsetliteral_2 = Collections.<String, List<String>>unmodifiableMap(_tempMap_2);
    Game _newGame_2 = this.newGame(_xsetliteral_2);
    boolean _isPlayer_2 = this.model.isPlayer(_newGame_2);
    TestCase.assertTrue(_isPlayer_2);
  }
  
  public void testEnsureIsPlayer() {
    try {
      Map<String,List<Object>> _xsetliteral = null;
      Map<String,List<Object>> _tempMap = Maps.<String, List<Object>>newHashMap();
      _tempMap.put("players", Collections.<Object>unmodifiableList(Lists.<Object>newArrayList()));
      _xsetliteral = Collections.<String, List<Object>>unmodifiableMap(_tempMap);
      Game _newGame = this.newGame(_xsetliteral);
      this.model.ensureIsPlayer(_newGame);
      TestCase.fail();
    } catch (final Throwable _t) {
      if (_t instanceof RuntimeException) {
        final RuntimeException expected = (RuntimeException)_t;
      } else {
        throw Exceptions.sneakyThrow(_t);
      }
    }
  }
  
  public void testEnsureIsCurrentPlayer() {
    try {
      Map<String,Object> _xsetliteral = null;
      Map<String,Object> _tempMap = Maps.<String, Object>newHashMap();
      _tempMap.put("players", Collections.<Object>unmodifiableList(Lists.<Object>newArrayList()));
      _tempMap.put("currentPlayerNumber", Long.valueOf(0L));
      _xsetliteral = Collections.<String, Object>unmodifiableMap(_tempMap);
      Game _newGame = this.newGame(_xsetliteral);
      this.model.ensureIsCurrentPlayer(_newGame);
      TestCase.fail();
    } catch (final Throwable _t) {
      if (_t instanceof RuntimeException) {
        final RuntimeException expected = (RuntimeException)_t;
      } else {
        throw Exceptions.sneakyThrow(_t);
      }
    }
  }
}
