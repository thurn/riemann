package ca.thurn.noughts.shared

import java.util.List
import java.util.Map

class Action {
  @Property String player;
  
  @Property Long playerNumber;
  
  @Property String gameId;
  
  @Property Boolean submitted;
  
  @Property final List<Command> commands;
  
  @Property final List<Command> futureCommands;
  
  new() {
    _commands = newArrayList()
    _futureCommands = newArrayList()
  }
  
  new(Map<String, Object> map) {
    _player = map.get("player") as String
    _playerNumber = map.get("playerNumber") as Long
    _gameId = map.get("gameId") as String
    _submitted = map.get("submitted") as Boolean
    if (map.containsKey("commands")) {
      val commands = map.get("commands") as List<Map<String, Object>>
      _commands = commands.map([object | new Command(object)])
    } else {
      _commands = newArrayList()    
    }
    if (map.containsKey("futureCommands")) {
      val futureCommands = map.get("futureCommands") as List<Map<String, Object>>
      _futureCommands = futureCommands.map([object | new Command(object)])
    } else {
      _futureCommands = newArrayList()
    }  
  }
  
  def serialize() {
    return #{
      "player" -> player,
      "playerNumber" -> playerNumber,
      "gameId" -> gameId,
      "submitted" -> submitted,
      "commands" -> commands.map([command | command.serialize()]),
      "futureCommands" -> futureCommands.map([command | command.serialize()])
    }
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