package ca.thurn.noughts.shared

import java.util.Map

class Command {
  @Property Long column
  @Property Long row
  
  new() {
  }
  
  new(Map<String, Object> map) {
    if (map.containsKey("column")) {
      _column = map.get("column") as Long
    }
    if (map.containsKey("row")) {
      _row = map.get("row") as Long
    }
  }
  
  def serialize() {
    return #{
      "column" -> column,
      "row" -> row
    }
  }
  
  override toString() {
    return "Command: " + serialize().toString()
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
    val other = obj as Command
    return serialize().equals(other.serialize())
  }
  
}