package ca.thurn.noughts

import com.google.gwt.core.client.ScriptInjector
import com.google.gwt.core.client.Callback

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
		val model = new Model("userId")
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