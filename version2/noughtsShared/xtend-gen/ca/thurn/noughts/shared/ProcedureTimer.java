package ca.thurn.noughts.shared;

import java.util.Timer;
import org.eclipse.xtext.xbase.lib.Procedures.Procedure0;

@SuppressWarnings("all")
public class ProcedureTimer extends Timer {
  private final Procedure0 function;
  
  public ProcedureTimer(final Procedure0 function) {
    this.function = function;
  }
  
  public void run() {
    this.function.apply();
  }
}
