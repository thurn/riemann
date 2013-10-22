package ca.thurn.noughts.shared

import java.util.Map

class Command extends Entity {
  @Property Integer column
  @Property Integer row
  
  new() {
  }
  
  new(Map<String, Object> map) {
    _column = toInteger(map.get("column"))
    _row = toInteger(map.get("row"))
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