package ca.thurn.noughts.android;

import android.content.Context;
import android.graphics.Canvas;
import android.util.AttributeSet;
import android.util.Log;
import android.view.MotionEvent;
import android.view.View;
import android.view.View.OnTouchListener;
import ca.thurn.noughts.shared.Command;
import ca.thurn.noughts.shared.Game;

import com.caverock.androidsvg.SVG;
import com.caverock.androidsvg.SVGParseException;

public class GameView extends View implements OnTouchListener {

  private Game mGame;
  private CommandHandler mCommandHandler;
  private final SVG mBackground;
  
  public GameView(Context context, AttributeSet attrs) {
    super(context, attrs);
    setOnTouchListener(this);
    try {
      mBackground = SVG.getFromResource(getContext(), R.raw.background);
    } catch (SVGParseException e) {
      throw new RuntimeException(e);
    }
  }
  
  public void updateGame(Game game) {
    mGame = game;
    postInvalidate();
  }
  
  public void setCommandHandler(CommandHandler commandListener) {
    mCommandHandler = commandListener;
  }
  
  @Override
  protected void onDraw(Canvas canvas) {
    mBackground.renderToCanvas(canvas);
  }

  @Override
  public boolean onTouch(View v, MotionEvent event) {
    if (event.getActionMasked() != MotionEvent.ACTION_UP) {
      return true;
    }
    handleTouch(event.getX(), event.getY());
    return true;
  }
  
  private void handleTouch(float x, float y) {
    if (y < 150 || y > 920) {
      return; // Outside of game grid, do nothing
    }
    long column = (int) (x / 256.0);
    long row = (int) ((y - 150) / 256.0);
    Command command = new Command();
    command.setColumn(column);
    command.setRow(row);
    if (mCommandHandler.isLegalCommand(command)) {
      mCommandHandler.addCommand(command);
    }
  }
  
}
