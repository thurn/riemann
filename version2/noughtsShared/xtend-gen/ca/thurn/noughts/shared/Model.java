package ca.thurn.noughts.shared;

import ca.thurn.noughts.shared.ChildAddedListener;
import ca.thurn.noughts.shared.Game;
import ca.thurn.noughts.shared.MapStringObject;
import com.firebase.client.DataSnapshot;
import com.firebase.client.Firebase;
import com.google.common.base.Objects;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import org.eclipse.xtext.xbase.lib.CollectionLiterals;
import org.eclipse.xtext.xbase.lib.Procedures.Procedure1;
import org.eclipse.xtext.xbase.lib.Procedures.Procedure2;

@SuppressWarnings("all")
public class Model {
  private final String userId;
  
  private final Firebase firebase;
  
  private final Map<String,Game> games;
  
  private final List<Procedure1<Game>> gameAddedCallbacks;
  
  public Model(final String userId) {
    this.userId = userId;
    Firebase _firebase = new Firebase("http://www.example.com");
    this.firebase = _firebase;
    HashMap<String,Game> _hashMap = new HashMap<String, Game>();
    this.games = _hashMap;
    ArrayList<Procedure1<Game>> _newArrayList = CollectionLiterals.<Procedure1<Game>>newArrayList();
    this.gameAddedCallbacks = _newArrayList;
    Firebase _child = this.firebase.child("games");
    final Procedure2<DataSnapshot,String> _function = new Procedure2<DataSnapshot,String>() {
      public void apply(final DataSnapshot snapshot, final String prevChildName) {
        MapStringObject _mapStringObject = new MapStringObject();
        Map<String,Object> _value = snapshot.<Map<String,Object>>getValue(_mapStringObject);
        Game _game = new Game(_value);
        final Game game = _game;
        String _name = snapshot.getName();
        Model.this.games.put(_name, game);
        for (final Procedure1<Game> callback : Model.this.gameAddedCallbacks) {
          callback.apply(game);
        }
      }
    };
    ChildAddedListener _childAddedListener = new ChildAddedListener(_function);
    _child.addChildEventListener(_childAddedListener);
  }
  
  public final static long X_PLAYER = 0L;
  
  public final static long O_PLAYER = 1L;
  
  public boolean addGameAddedCallback(final Procedure1<Game> callback) {
    boolean _add = this.gameAddedCallbacks.add(callback);
    return _add;
  }
  
  public Game newGame(final Map<String,String> userProfile, final Map<String,String> opponentProfile) {
    Firebase _child = this.firebase.child("games");
    final Firebase push = _child.push();
    String _name = push.getName();
    Game _game = new Game(_name);
    final Game game = _game;
    List<String> _players = game.getPlayers();
    _players.add(this.userId);
    game.setCurrentPlayerNumber(Long.valueOf(Model.X_PLAYER));
    game.setCurrentAction(null);
    long _currentTimeMillis = System.currentTimeMillis();
    game.setLastModified(Long.valueOf(_currentTimeMillis));
    game.setGameOver(Boolean.valueOf(false));
    game.setActionCount(Long.valueOf(0L));
    boolean _notEquals = (!Objects.equal(userProfile, null));
    if (_notEquals) {
      Map<String,Map<String,String>> _profiles = game.getProfiles();
      String _get = userProfile.get("facebookId");
      _profiles.put(_get, userProfile);
    }
    boolean _notEquals_1 = (!Objects.equal(opponentProfile, null));
    if (_notEquals_1) {
      Map<String,Map<String,String>> _profiles_1 = game.getProfiles();
      String _get_1 = opponentProfile.get("facebookId");
      _profiles_1.put(_get_1, opponentProfile);
      List<String> _players_1 = game.getPlayers();
      String _get_2 = opponentProfile.get("facebookId");
      _players_1.add(_get_2);
    }
    Map<String,Object> _serialize = game.serialize();
    push.setValue(_serialize);
    return game;
  }
  
  public void die(final String message) {
    RuntimeException _runtimeException = new RuntimeException(message);
    throw _runtimeException;
  }
  
  /**
   * Returns true if the current user is the current player in the provided
   * game.
   */
  public boolean isCurrentPlayer(final Game game) {
    boolean _xifexpression = false;
    boolean _isGameOver = game.isGameOver();
    if (_isGameOver) {
      _xifexpression = false;
    } else {
      String _currentPlayerId = game.currentPlayerId();
      boolean _equals = Objects.equal(_currentPlayerId, this.userId);
      _xifexpression = _equals;
    }
    return _xifexpression;
  }
  
  /**
   * Returns true if the current user is a player in the provided game.
   */
  public boolean isPlayer(final Game game) {
    List<String> _players = game.getPlayers();
    return _players.contains(this.userId);
  }
  
  /**
   * Ensures the current user is a player in the provided game.
   */
  public void ensureIsPlayer(final Game game) {
    boolean _isPlayer = this.isPlayer(game);
    boolean _not = (!_isPlayer);
    if (_not) {
      String _plus = ("Unauthorized user: " + this.userId);
      this.die(_plus);
    }
  }
  
  /**
   * Ensures the current user is the current player in the provided game.
   */
  public void ensureIsCurrentPlayer(final Game game) {
    boolean _isCurrentPlayer = this.isCurrentPlayer(game);
    boolean _not = (!_isCurrentPlayer);
    if (_not) {
      this.die("Unauthorized user:  + userId");
    }
  }
}
