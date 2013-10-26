package ca.thurn.noughts.android;

import java.util.List;

import android.content.Context;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ArrayAdapter;
import android.widget.TextView;
import ca.thurn.noughts.shared.Game;
import ca.thurn.noughts.shared.Model;

public class GameListAdapter extends ArrayAdapter<Game> {

  private final int mResource;
  private final Model mModel;
  
  public GameListAdapter(Context context, int resource, List<Game> objects, Model model) {
    super(context, resource, objects);
    mResource = resource;
    mModel = model;
  }
  
  @Override
  public View getView(int position, View convertView, ViewGroup parent) {
    if (convertView != null) {
      return convertView;
    }
    LayoutInflater inflater = LayoutInflater.from(getContext());
    TextView result = (TextView)inflater.inflate(mResource, parent, false);
    Game game = getItem(position);
    String opponentId = mModel.getOpponentId(game);
    if (opponentId != null) {
      result.setText(R.string.game_anonymous);
      result.setCompoundDrawablesWithIntrinsicBounds(R.drawable.ic_anonymous_opponent, 0, 0, 0);
    } else {
      result.setText(R.string.game_no_opponent);
      result.setCompoundDrawablesWithIntrinsicBounds(R.drawable.ic_no_opponent, 0, 0, 0);
    }
    return result;
  }

}
