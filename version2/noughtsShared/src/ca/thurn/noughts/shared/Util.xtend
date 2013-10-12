package ca.thurn.noughts.shared

import java.util.Map

class Util {
  def static Map m(Pair... pairs) {
    return newHashMap(pairs)
  }
}