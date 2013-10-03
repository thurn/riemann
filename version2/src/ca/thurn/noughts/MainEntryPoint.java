package ca.thurn.noughts;

import com.google.gwt.core.client.EntryPoint;

public class MainEntryPoint implements EntryPoint {
  @Override
  public void onModuleLoad() {
		Client client = new Client();
		//Model model = new Model("usrId");
		//Game g = model.newGame(null, null);
		//log(g.getId());
	}

  public static native void log(String message) /*-{
      console.log(message);
  }-*/;

  public static native void debugger() /*-{
      debugger;
  }-*/;
}
