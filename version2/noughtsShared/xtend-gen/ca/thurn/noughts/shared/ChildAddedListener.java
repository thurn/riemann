package ca.thurn.noughts.shared;

import ca.thurn.noughts.shared.DoNothingChildEventListener;
import com.firebase.client.DataSnapshot;
import org.eclipse.xtext.xbase.lib.Procedures.Procedure2;

@SuppressWarnings("all")
public class ChildAddedListener extends DoNothingChildEventListener {
  private final Procedure2<DataSnapshot,String> function;
  
  public ChildAddedListener(final Procedure2<DataSnapshot,String> function) {
    this.function = function;
  }
  
  public void onChildAdded(final DataSnapshot snapshot, final String previousChildName) {
    this.function.apply(snapshot, previousChildName);
  }
}
