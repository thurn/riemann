package ca.thurn.noughts.shared;

import com.firebase.client.ChildEventListener;
import com.firebase.client.DataSnapshot;

@SuppressWarnings("all")
public class DoNothingChildEventListener implements ChildEventListener {
  public void onCancelled() {
    RuntimeException _runtimeException = new RuntimeException("ChildEventListener cancelled!");
    throw _runtimeException;
  }
  
  public void onChildAdded(final DataSnapshot snapshot, final String previousChildName) {
  }
  
  public void onChildChanged(final DataSnapshot snapshot, final String previousChildName) {
  }
  
  public void onChildMoved(final DataSnapshot snapshot, final String previousChildName) {
  }
  
  public void onChildRemoved(final DataSnapshot snapshot) {
  }
}
