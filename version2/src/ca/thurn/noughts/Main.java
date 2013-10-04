package ca.thurn.noughts;

import com.google.gwt.core.client.EntryPoint;

public class Main implements EntryPoint {
  @Override
  public void onModuleLoad() {
		Client client = new Client();
	}

  public static native void log(String message) /*-{
      console.log(message);
  }-*/;

  public static native void debugger() /*-{
      debugger;
  }-*/;
}
