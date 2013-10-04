package ca.thurn.noughts

import com.google.gwt.core.client.ScriptInjector
import com.google.gwt.core.client.Callback
import ca.thurn.firebase.Firebase
import ca.thurn.firebase.ValueEventListener
import ca.thurn.firebase.DataSnapshot

class Client {
	new() {
		println("Injecting")
    	ScriptInjector
    		.fromUrl("http://cdn.firebase.com/v0/firebase.js")
    		.setCallback(new RunnableCallback([ |
    			onFirebaseLoad()
    		]))
    		.inject()
	}
	
	def onFirebaseLoad() {
		val firebase = new Firebase("http://www.example.com")
		firebase.addListenerForSingleValueEvent(new FunctionValueEventListener([ snapshot |
			println("single value event")
			return null
		]))
		firebase.setValue("bar")
		//val model = new Model("userId")
		println("Injected")
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