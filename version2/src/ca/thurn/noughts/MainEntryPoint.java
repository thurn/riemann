package ca.thurn.noughts;

import com.google.gwt.core.client.EntryPoint;

public class MainEntryPoint implements EntryPoint {
  @Override
  public void onModuleLoad() {
		System.out.println("Hello, world");
		log("hello, world");
	}

	public native void log(String message) /*-{
		console.log(message);
	}-*/;
}
