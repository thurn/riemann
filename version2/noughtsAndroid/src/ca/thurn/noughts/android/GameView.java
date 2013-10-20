package ca.thurn.noughts.android;

import com.caverock.androidsvg.SVG;
import com.caverock.androidsvg.SVGParseException;

import android.content.Context;
import android.graphics.Canvas;
import android.graphics.Paint;
import android.graphics.Picture;
import android.util.AttributeSet;
import android.util.Log;
import android.view.View;
import ca.thurn.noughts.shared.Game;

public class GameView extends View {

  private Game mGame;
  
  public GameView(Context context, AttributeSet attrs) {
    super(context, attrs);
  }
  
  public void updateGame(Game game) {
    mGame = game;
    postInvalidate();
  }
  
  @Override
  protected void onDraw(Canvas canvas) {
    try {
      canvas.scale(4, 4);
      SVG svg = SVG.getFromResource(getContext(), R.raw.x);
      svg.renderToCanvas(canvas);
    } catch (SVGParseException e) {
      throw new RuntimeException(e);
    }
    Log.e("dthurn", ">>>>> onDraw ");
  }
  
}
