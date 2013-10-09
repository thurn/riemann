package ca.thurn.noughts.shared;

import com.google.common.base.Objects;
import com.google.common.collect.Maps;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import org.eclipse.xtext.xbase.lib.CollectionLiterals;

@SuppressWarnings("all")
public class Game {
  /**
   * The game ID
   */
  private final String _id;
  
  /**
   * The game ID
   */
  public String getId() {
    return this._id;
  }
  
  /**
   * An array of the players in the game, which can be though of as a bimap
   * from Player Number to Player ID. A player who leaves the game will have
   * her entry in this array replaced with null.
   */
  private final List<String> _players;
  
  /**
   * An array of the players in the game, which can be though of as a bimap
   * from Player Number to Player ID. A player who leaves the game will have
   * her entry in this array replaced with null.
   */
  public List<String> getPlayers() {
    return this._players;
  }
  
  /**
   * A mapping from player IDs to profile information about the player.
   */
  private final Map<String,Map<String,String>> _profiles;
  
  /**
   * A mapping from player IDs to profile information about the player.
   */
  public Map<String,Map<String,String>> getProfiles() {
    return this._profiles;
  }
  
  /**
   * The number of the player whose turn it is, that is, their index within
   * the players array. -1 when the game is not in progress.
   */
  private Long _currentPlayerNumber;
  
  /**
   * The number of the player whose turn it is, that is, their index within
   * the players array. -1 when the game is not in progress.
   */
  public Long getCurrentPlayerNumber() {
    return this._currentPlayerNumber;
  }
  
  /**
   * The number of the player whose turn it is, that is, their index within
   * the players array. -1 when the game is not in progress.
   */
  public void setCurrentPlayerNumber(final Long currentPlayerNumber) {
    this._currentPlayerNumber = currentPlayerNumber;
  }
  
  /**
   * ID of action currently being constructed, or null if no action is under
   * construction (or the game is over). Should never polong to a submitted
   * action. Null when the game is not in progress.
   */
  private String _currentAction;
  
  /**
   * ID of action currently being constructed, or null if no action is under
   * construction (or the game is over). Should never polong to a submitted
   * action. Null when the game is not in progress.
   */
  public String getCurrentAction() {
    return this._currentAction;
  }
  
  /**
   * ID of action currently being constructed, or null if no action is under
   * construction (or the game is over). Should never polong to a submitted
   * action. Null when the game is not in progress.
   */
  public void setCurrentAction(final String currentAction) {
    this._currentAction = currentAction;
  }
  
  /**
   * UNIX timestamp of time when game was last modified.
   */
  private Long _lastModified;
  
  /**
   * UNIX timestamp of time when game was last modified.
   */
  public Long getLastModified() {
    return this._lastModified;
  }
  
  /**
   * UNIX timestamp of time when game was last modified.
   */
  public void setLastModified(final Long lastModified) {
    this._lastModified = lastModified;
  }
  
  /**
   * Facebook request ID associated with this game.
   */
  private String _requestId;
  
  /**
   * Facebook request ID associated with this game.
   */
  public String getRequestId() {
    return this._requestId;
  }
  
  /**
   * Facebook request ID associated with this game.
   */
  public void setRequestId(final String requestId) {
    this._requestId = requestId;
  }
  
  /**
   * List of IDs of the players who won this game. In the case of a draw, it
   * should contain all of the drawing players. In the case of a "nobody
   * wins" situation, an empty list should be present. This field cannot be
   * present on a game which is still in progress.
   */
  private final List<String> _victors;
  
  /**
   * List of IDs of the players who won this game. In the case of a draw, it
   * should contain all of the drawing players. In the case of a "nobody
   * wins" situation, an empty list should be present. This field cannot be
   * present on a game which is still in progress.
   */
  public List<String> getVictors() {
    return this._victors;
  }
  
  /**
   * True if this game has ended.
   */
  private Boolean _gameOver;
  
  /**
   * Number of (submitted) actions so far in this game.
   */
  private Long _actionCount;
  
  /**
   * Number of (submitted) actions so far in this game.
   */
  public Long getActionCount() {
    return this._actionCount;
  }
  
  /**
   * Number of (submitted) actions so far in this game.
   */
  public void setActionCount(final Long actionCount) {
    this._actionCount = actionCount;
  }
  
  /**
   * An array of player IDs who have resigned the game.
   */
  private final List<String> _resignedPlayers;
  
  /**
   * An array of player IDs who have resigned the game.
   */
  public List<String> getResignedPlayers() {
    return this._resignedPlayers;
  }
  
  public Game(final String gameId) {
    this._id = gameId;
    ArrayList<String> _newArrayList = CollectionLiterals.<String>newArrayList();
    this._players = _newArrayList;
    HashMap<String,Map<String,String>> _newHashMap = CollectionLiterals.<String, Map<String,String>>newHashMap();
    this._profiles = _newHashMap;
    ArrayList<String> _newArrayList_1 = CollectionLiterals.<String>newArrayList();
    this._victors = _newArrayList_1;
    ArrayList<String> _newArrayList_2 = CollectionLiterals.<String>newArrayList();
    this._resignedPlayers = _newArrayList_2;
  }
  
  public Game(final Map<String,Object> gameMap) {
    boolean _containsKey = gameMap.containsKey("id");
    boolean _not = (!_containsKey);
    if (_not) {
      IllegalArgumentException _illegalArgumentException = new IllegalArgumentException("Game map is missing ID!");
      throw _illegalArgumentException;
    }
    Object _get = gameMap.get("id");
    this._id = ((String) _get);
    boolean _containsKey_1 = gameMap.containsKey("players");
    if (_containsKey_1) {
      Object _get_1 = gameMap.get("players");
      this._players = ((List<String>) _get_1);
    } else {
      ArrayList<String> _newArrayList = CollectionLiterals.<String>newArrayList();
      this._players = _newArrayList;
    }
    boolean _containsKey_2 = gameMap.containsKey("profiles");
    if (_containsKey_2) {
      Object _get_2 = gameMap.get("profiles");
      this._profiles = ((Map<String,Map<String,String>>) _get_2);
    } else {
      HashMap<String,Map<String,String>> _newHashMap = CollectionLiterals.<String, Map<String,String>>newHashMap();
      this._profiles = _newHashMap;
    }
    Object _get_3 = gameMap.get("currentPlayerNumber");
    this._currentPlayerNumber = ((Long) _get_3);
    Object _get_4 = gameMap.get("currentAction");
    this._currentAction = ((String) _get_4);
    Object _get_5 = gameMap.get("lastModified");
    this._lastModified = ((Long) _get_5);
    Object _get_6 = gameMap.get("requestId");
    this._requestId = ((String) _get_6);
    boolean _containsKey_3 = gameMap.containsKey("victors");
    if (_containsKey_3) {
      Object _get_7 = gameMap.get("victors");
      this._victors = ((List<String>) _get_7);
    } else {
      ArrayList<String> _newArrayList_1 = CollectionLiterals.<String>newArrayList();
      this._victors = _newArrayList_1;
    }
    Object _get_8 = gameMap.get("gameOver");
    this._gameOver = ((Boolean) _get_8);
    Object _get_9 = gameMap.get("actionCount");
    this._actionCount = ((Long) _get_9);
    boolean _containsKey_4 = gameMap.containsKey("resignedPlayers");
    if (_containsKey_4) {
      Object _get_10 = gameMap.get("resignedPlayers");
      this._resignedPlayers = ((List<String>) _get_10);
    } else {
      ArrayList<String> _newArrayList_2 = CollectionLiterals.<String>newArrayList();
      this._resignedPlayers = _newArrayList_2;
    }
  }
  
  public String currentPlayerId() {
    List<String> _players = this.getPlayers();
    Long _currentPlayerNumber = this.getCurrentPlayerNumber();
    int _intValue = _currentPlayerNumber.intValue();
    return _players.get(_intValue);
  }
  
  public Boolean setGameOver(final Boolean gameOver) {
    Boolean __gameOver = this._gameOver = gameOver;
    return __gameOver;
  }
  
  public boolean isGameOver() {
    boolean _and = false;
    boolean _notEquals = (!Objects.equal(this._gameOver, null));
    if (!_notEquals) {
      _and = false;
    } else {
      boolean _equals = ((this._gameOver).booleanValue() == true);
      _and = (_notEquals && _equals);
    }
    return _and;
  }
  
  public Map<String,Object> serialize() {
    Map<String,Object> _xsetliteral = null;
    String _id = this.getId();
    List<String> _players = this.getPlayers();
    Map<String,Map<String,String>> _profiles = this.getProfiles();
    Long _currentPlayerNumber = this.getCurrentPlayerNumber();
    String _currentAction = this.getCurrentAction();
    Long _lastModified = this.getLastModified();
    String _requestId = this.getRequestId();
    List<String> _victors = this.getVictors();
    boolean _isGameOver = this.isGameOver();
    Long _actionCount = this.getActionCount();
    List<String> _resignedPlayers = this.getResignedPlayers();
    Map<String,Object> _tempMap = Maps.<String, Object>newHashMap();
    _tempMap.put("id", _id);
    _tempMap.put("players", _players);
    _tempMap.put("profiles", _profiles);
    _tempMap.put("currentPlayerNumber", _currentPlayerNumber);
    _tempMap.put("currentAction", _currentAction);
    _tempMap.put("lastModified", _lastModified);
    _tempMap.put("requestId", _requestId);
    _tempMap.put("victors", _victors);
    _tempMap.put("gameOver", Boolean.valueOf(_isGameOver));
    _tempMap.put("actionCount", _actionCount);
    _tempMap.put("resignedPlayers", _resignedPlayers);
    _xsetliteral = Collections.<String, Object>unmodifiableMap(_tempMap);
    return _xsetliteral;
  }
  
  public String toString() {
    Map<String,Object> _serialize = this.serialize();
    String _string = _serialize.toString();
    return ("Game: " + _string);
  }
  
  public int hashCode() {
    Map<String,Object> _serialize = this.serialize();
    return _serialize.hashCode();
  }
  
  public boolean equals(final Object obj) {
    boolean _tripleEquals = (this == obj);
    if (_tripleEquals) {
      return true;
    }
    boolean _tripleEquals_1 = (obj == null);
    if (_tripleEquals_1) {
      return false;
    }
    Class<? extends Game> _class = this.getClass();
    Class<? extends Object> _class_1 = obj.getClass();
    boolean _tripleNotEquals = (_class != _class_1);
    if (_tripleNotEquals) {
      return false;
    }
    final Game other = ((Game) obj);
    Map<String,Object> _serialize = this.serialize();
    Map<String,Object> _serialize_1 = other.serialize();
    return _serialize.equals(_serialize_1);
  }
}
