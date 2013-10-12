package ca.thurn.noughts.shared

import com.firebase.client.MutableData
import com.firebase.client.Transaction
import com.firebase.client.FirebaseError
import com.firebase.client.DataSnapshot

class TransactionHandler implements Transaction.Handler {
  val Procedures.Procedure1<MutableData> _function
  
  new(Procedures.Procedure1<MutableData> function) {
    _function = function
  }
  
  override doTransaction(MutableData data) {
    _function.apply(data)
    return Transaction.success(data);
  }
  
  override onComplete(FirebaseError error, boolean done, DataSnapshot snapshot) {
  }
  
}