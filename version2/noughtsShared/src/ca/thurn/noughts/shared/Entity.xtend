package ca.thurn.noughts.shared

abstract class Entity {
  /**
   * Casts the supplied object to an integer
   * 
   * @param object The object
   * @return A corresponding int
   */
  def toInteger(Object object) {
    if (object == null) {
      return null
    }
    return (object as Number).intValue()
  }
}