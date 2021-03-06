package ca.thurn.noughts.shared

import com.firebase.client.ChildEventListener
import com.firebase.client.DataSnapshot
import java.util.Timer
import com.firebase.client.ValueEventListener

class DoNothingChildEventListener implements ChildEventListener {
	
	override onCancelled() {
		throw new RuntimeException("ChildEventListener cancelled!")
	}
	
	override onChildAdded(DataSnapshot snapshot, String previousChildName) {
	}
	
	override onChildChanged(DataSnapshot snapshot, String previousChildName) {
	}
	
	override onChildMoved(DataSnapshot snapshot, String previousChildName) {
	}
	
	override onChildRemoved(DataSnapshot snapshot) {
	}
}

class FunctionValueEventListener implements ValueEventListener {
  
  val Procedures.Procedure1<DataSnapshot> _function;
  
  new(Procedures.Procedure1<DataSnapshot> function) {
    _function = function;
  }
  
  override onCancelled() {
  }
  
  override onDataChange(DataSnapshot snapshot) {
    _function.apply(snapshot);
  }
  
}

class ChildAddedListener extends DoNothingChildEventListener {
	val Procedures.Procedure2<DataSnapshot, String> function
	
	new(Procedures.Procedure2<DataSnapshot, String> function) {
		this.function = function
	}
	
	override onChildAdded(DataSnapshot snapshot, String previousChildName) {
		function.apply(snapshot, previousChildName)
	}
}

class ProcedureTimer extends Timer {
	val Procedures.Procedure0 function;
	
	new(Procedures.Procedure0 function) {
		this.function = function
	}
	
	def run() {
		function.apply()
	}
}