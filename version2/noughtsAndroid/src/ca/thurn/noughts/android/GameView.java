package ca.thurn.noughts.android;

import android.content.Context;
import android.graphics.Canvas;
import android.util.AttributeSet;
import android.util.Log;
import android.view.MotionEvent;
import android.view.View;
import android.view.View.OnTouchListener;
import ca.thurn.noughts.shared.Action;
import ca.thurn.noughts.shared.Command;
import ca.thurn.noughts.shared.Game;
import ca.thurn.noughts.shared.Model;

import com.caverock.androidsvg.SVG;
import com.caverock.androidsvg.SVGParseException;

public class GameView extends View implements OnTouchListener {

  private Game mGame;
  private CommandHandler mCommandHandler;
  private final SVG mBackground;
  private final SVG mXAsset;
  private final SVG mOAsset;
  
  public GameView(Context context, AttributeSet attrs) {
    super(context, attrs);
    setOnTouchListener(this);
    try {
      mBackground = SVG.getFromResource(getContext(), R.raw.background);
      mXAsset = SVG.getFromResource(getContext(), R.raw.x);
      mOAsset = SVG.getFromResource(getContext(), R.raw.o);
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
    for (Action action : mGame.getActions()) {
      for (Command command : action.getCommands()) {
        SVG asset = action.getPlayerNumber() == Model.X_PLAYER ? mXAsset : mOAsset;
        float x = command.getColumn() * 256;
        float y = (command.getRow() * 256) + 138;
        drawAsset(canvas, asset, x, y);
      }
    }
  }
  
  private void drawAsset(Canvas canvas, SVG svg, float x, float y) {
    canvas.translate(x, y);
    svg.renderToCanvas(canvas);
    canvas.translate(-x, -y);
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
    if (y < 138 || y > 903) {
      return; // Outside of game grid, do nothing
    }
    int column = (int) (x / 256.0);
    int row = (int) ((y - 150) / 256.0);
    Command command = new Command();
    command.setColumn(column);
    command.setRow(row);
    if (mCommandHandler.isLegalCommand(command)) {
      mCommandHandler.addCommand(command);
    }
  }
  
}
