package ca.thurn.noughts.android;

import ca.thurn.noughts.shared.Command;

public interface CommandHandler {
  public void addCommand(Command command);
  
  public boolean isLegalCommand(Command command);
}
