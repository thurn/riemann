package ca.thurn.noughts.shared

import com.firebase.client.Transaction
import com.firebase.client.MutableData
import com.firebase.client.FirebaseError
import com.firebase.client.DataSnapshot
import java.util.List
import java.util.ArrayList

class PushTransaction implements Transaction.Handler {
  
  val Object _value
  
  new(Object value) {
    _value = value
  }
  
  override doTransaction(MutableData data) {
    val list = data.getValue() as List<Object>
    val newList =
      if (list == null) {
        new ArrayList<Object>()
      } else {
        new ArrayList<Object>(list)
      }
    newList.add(_value)
    data.setValue(newList);
    return Transaction.success(data)
  }
  
  override onComplete(FirebaseError err, boolean done, DataSnapshot snapshot) {
    if (err == null) {
      throw new RuntimeException(err.message)
    }
  }
  
}