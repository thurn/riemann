package ca.thurn.noughts.shared

import java.util.List
import java.util.Map

class Action extends Entity {
  @Property String player;
  
  @Property Integer playerNumber;
  
  @Property String gameId;
  
  Boolean _submitted;
  
  @Property final List<Command> commands;
  
  @Property final List<Command> futureCommands;
  
  new() {
    _commands = newArrayList()
    _futureCommands = newArrayList()
  }
  
  new(Map<String, Object> map) {
    _player = map.get("player") as String
    _playerNumber = toInteger(map.get("playerNumber"))
    _gameId = map.get("gameId") as String
    _submitted = map.get("submitted") as Boolean
    _commands = newArrayList()    
    if (map.containsKey("commands")) {
      val commands = map.get("commands") as List<Map<String, Object>>
      for (object : commands) {
        _commands.add(new Command(object))
      }
    }
    _futureCommands = newArrayList()
    if (map.containsKey("futureCommands")) {
      val futureCommands = map.get("futureCommands") as List<Map<String, Object>>
      for (object : futureCommands) {
        _futureCommands.add(new Command(object))
      }
    }
  }
  
  def serialize() {
    return #{
      "player" -> _player,
      "playerNumber" -> _playerNumber,
      "gameId" -> _gameId,
      "submitted" -> _submitted,
      "commands" -> _commands.map([command | command.serialize()]),
      "futureCommands" -> _futureCommands.map([command | command.serialize()])
    }
  }
  
  def setSubmitted(Boolean submitted) {
    _submitted = submitted
  }
  
  def isSubmitted() {
    return _submitted != null && _submitted == true
  }
  
  override toString() {
    return "Action: " + serialize().toString()
  }
  
  override hashCode() {
    return serialize().hashCode()
  }
  
  override equals(Object obj) {
    if (this === obj) {
      return true
    }
    if (obj == null) {
      return false
    }
    if (getClass() !== obj.getClass()) {
      return false
    }
    val other = obj as Action
    return serialize().equals(other.serialize())
  }
}