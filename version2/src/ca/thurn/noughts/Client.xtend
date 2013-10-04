package ca.thurn.noughts

import com.google.gwt.core.client.ScriptInjector
import com.google.gwt.core.client.Callback
import ca.thurn.firebase.ValueEventListener
import ca.thurn.firebase.DataSnapshot
import ca.thurn.firebase.ChildEventListener

class Client {
	new() {
    	ScriptInjector
    		.fromUrl("http://cdn.firebase.com/v0/firebase.js")
    		.setCallback(new RunnableCallback([ |
    			onFirebaseLoad()
    		]))
    		.inject()
	}
	
	def onFirebaseLoad() {
		val model = new Model("122610483")
		model.newGame(null, null)
	}
}

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

class ChildAddedListener extends DoNothingChildEventListener {
	val Functions.Function2<DataSnapshot, String, Void> function
	
	new(Functions.Function2<DataSnapshot, String, Void> function) {
		this.function = function
	}
	
	override onChildAdded(DataSnapshot snapshot, String previousChildName) {
		function.apply(snapshot, previousChildName)
	}
}

class FunctionValueEventListener implements ValueEventListener {
	val Functions.Function1<DataSnapshot, Void> function
	
	new(Functions.Function1<DataSnapshot, Void> function) {
		this.function = function
	}

	override onCancelled() {
		throw new RuntimeException("ValueEventListener cancelled")
	}
	
	override onDataChange(DataSnapshot snapshot) {
		function.apply(snapshot)
	}
}

class RunnableCallback implements Callback<Void, Exception> {
	val Runnable runnable
	
	new(Runnable runnable) {
		this.runnable = runnable
	}
	
	override onFailure(Exception reason) {
		throw reason
	}
	
	override onSuccess(Void result) {
		runnable.run()
	}
}