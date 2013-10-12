package ca.thurn.noughts.shared

import com.firebase.client.Firebase
import com.firebase.client.ChildEventListener
import com.firebase.client.DataSnapshot
import java.util.Map
import java.util.List

class Callbacks<T> implements ChildEventListener {
  val Firebase _firebase
  val Functions.Function1<Map<String,Object>, T> _unserializer
  @Property val List<Procedures.Procedure1<T>> childAddedCallbacks
  @Property val List<Procedures.Procedure1<T>> childChangedCallbacks
  @Property val List<Procedures.Procedure1<T>> childMovedCallbacks
  @Property val List<Procedures.Procedure1<T>> childRemovedCallbacks
  
  new(Firebase firebase, Functions.Function1<Map<String,Object>, T> unserializer) {
    _firebase = firebase
    _childAddedCallbacks = newArrayList()
    _childChangedCallbacks = newArrayList()
    _childMovedCallbacks = newArrayList()
    _childRemovedCallbacks = newArrayList()
    _unserializer = unserializer
    firebase.addChildEventListener(this)
  }
  
  override onCancelled() {
    throw new NoughtsException("Unexpected listener cancellation")
  }
  
  override onChildAdded(DataSnapshot snapshot, String prev) {
    val object = _unserializer.apply(snapshot.getValue() as Map<String, Object>)
    _childAddedCallbacks.forEach([callback | callback.apply(object)])
  }
  
  override onChildChanged(DataSnapshot snapshot, String prev) {
    val object = _unserializer.apply(snapshot.getValue() as Map<String, Object>)
    _childChangedCallbacks.forEach([callback | callback.apply(object)])
  }
  
  override onChildMoved(DataSnapshot snapshot, String prev) {
    val object = _unserializer.apply(snapshot.getValue() as Map<String, Object>)
    _childMovedCallbacks.forEach([callback | callback.apply(object)])
  }
  
  override onChildRemoved(DataSnapshot snapshot) {
    val object = _unserializer.apply(snapshot.getValue() as Map<String, Object>)
    _childRemovedCallbacks.forEach([callback | callback.apply(object)])
  }
  
}