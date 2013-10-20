package ca.thurn.noughts.android;

import android.app.Fragment;
import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.TextView;
import ca.thurn.noughts.shared.Game;
import ca.thurn.noughts.shared.Model;

/**
 * Fragment that appears in the "content_frame", shows a planet
 */
public class GameFragment extends Fragment {
    public static final String ARG_GAME_ID = "game_id";
    public static final String ARG_USER_ID = "user_id";
    // If true, create an new game instead of displaying the game in ARG_GAME_ID: 
    public static final String ARG_SHOULD_CREATE_GAME = "should_create_game";
    public static final String ARG_USER_PROFILE = "user_profile";
    public static final String ARG_OPPONENT_PROFILE = "opponent_profile";
    
    // Model, initialized with ARG_USER_ID:
    private Model mModel;
    // The game, null until the onGameReady() callback is invoked:
    private Game mGame;
    // Reference to the top-level fragment_game layout:
    private View mGameView;

    public GameFragment() {}

    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container,
            Bundle savedInstanceState) {
        mGameView = inflater.inflate(R.layout.fragment_game, container, false);
        String userId = getArguments().getString(ARG_USER_ID);
        mModel = Model.newFromUserId(userId);
        
        boolean createNewGame = getArguments().getBoolean(ARG_SHOULD_CREATE_GAME);
        if (createNewGame) {
          onGameReady(mModel.newGame(null, null));
        } else {
          throw new RuntimeException("wtf");
        }
        return mGameView;
    }
    
    public void onGameReady(Game game) {
      mGame = game;
      TextView text = (TextView)mGameView.findViewById(R.id.game_detail);
      text.setText(mGame.getId());
    }
}