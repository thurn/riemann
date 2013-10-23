package ca.thurn.noughts.android;

import java.util.logging.LogManager;

import org.eclipse.xtext.xbase.lib.Procedures;

import android.app.Fragment;
import android.os.Bundle;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.Menu;
import android.view.MenuInflater;
import android.view.MenuItem;
import android.view.View;
import android.view.View.OnClickListener;
import android.view.ViewGroup;
import android.widget.TextView;
import ca.thurn.noughts.shared.Command;
import ca.thurn.noughts.shared.Game;
import ca.thurn.noughts.shared.Model;

import com.example.android.cheatsheet.CheatSheet;

/**
 * Fragment that appears in the "content_frame", shows a planet
 */
public class GameFragment extends Fragment implements CommandHandler{
    public static final String ARG_GAME_ID = "game_id";
    public static final String ARG_USER_ID = "user_id";
    public static final String ARG_LOCAL_MULTIPLAYER = "local_multiplayer";
    // If true, create an new game instead of displaying the game in ARG_GAME_ID: 
    public static final String ARG_SHOULD_CREATE_GAME = "should_create_game";
    public static final String ARG_USER_PROFILE = "user_profile";
    public static final String ARG_OPPONENT_PROFILE = "opponent_profile";
    
    // Model, initialized with ARG_USER_ID:
    private Model mModel;
    // The game
    private Game mGame;
    // Reference to the top-level fragment_game layout:
    private GameView mGameView;

    public GameFragment() {}

    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container,
            Bundle savedInstanceState) {
        mGameView = (GameView)inflater.inflate(R.layout.fragment_game, container, false);
        mGameView.setLayerType(View.LAYER_TYPE_SOFTWARE, null);
        mGameView.setCommandHandler(this);
        String userId = getArguments().getString(ARG_USER_ID);
        boolean localMultiplayer = getArguments().getBoolean(ARG_LOCAL_MULTIPLAYER);
        mModel = Model.newFromUserId(userId);
        setHasOptionsMenu(true);
        getActivity().setTitle(R.string.app_name);
        
        boolean createNewGame = getArguments().getBoolean(ARG_SHOULD_CREATE_GAME);
        if (createNewGame) {
          mGame = mModel.newGame(localMultiplayer, null, null);
          mModel.addGameChangeListener(mGame.getId(), new Procedures.Procedure1<Game>() {
            @Override
            public void apply(Game game) {
              onGameUpdate(game);
            }
          });
          onGameUpdate(mGame);
        } else {
          throw new RuntimeException("wtf");
        }
        return mGameView;
    }
    
    @Override
    public void onCreateOptionsMenu(Menu menu, MenuInflater inflater) {
      inflater.inflate(R.menu.main, menu);
      MenuItem submitItem = menu.findItem(R.id.action_submit);
      submitItem.setEnabled(false);
      TextView submitView = (TextView)submitItem.getActionView();
      submitView.setEnabled(false);
      submitView.setText(R.string.action_submit);
      submitView.setCompoundDrawablesWithIntrinsicBounds(R.drawable.ic_submit_disabled, 0, 0, 0);
      submitView.setOnClickListener(new OnClickListener() {
        @Override
        public void onClick(View v) {
          mModel.submitCurrentAction(mGame);
        }
      });
      CheatSheet.setup(submitView, R.string.action_submit);
      super.onCreateOptionsMenu(menu, inflater);
    }
    
    @Override
    public void onPrepareOptionsMenu (Menu menu) {
      MenuItem submitItem = menu.findItem(R.id.action_submit);
      boolean canSubmit = mModel.canSubmit(mGame);
      submitItem.setEnabled(canSubmit);
      TextView submitView = (TextView)submitItem.getActionView();
      submitView.setEnabled(canSubmit);
      if (canSubmit) {
        submitView.setCompoundDrawablesWithIntrinsicBounds(R.drawable.ic_submit, 0, 0, 0);
      } else {
        submitView.setCompoundDrawablesWithIntrinsicBounds(R.drawable.ic_submit_disabled, 0, 0, 0);
      }
      boolean canUndo = mModel.canUndo(mGame);
      menu.findItem(R.id.action_undo).setEnabled(canUndo);
      if (canUndo) {
        menu.findItem(R.id.action_undo).setIcon(R.drawable.ic_undo);
      } else {
        menu.findItem(R.id.action_undo).setIcon(R.drawable.ic_undo_disabled);
      }
      boolean canRedo = mModel.canRedo(mGame);
      menu.findItem(R.id.action_redo).setEnabled(canRedo);
      if (canRedo) {
        menu.findItem(R.id.action_redo).setIcon(R.drawable.ic_redo);
      } else {
        menu.findItem(R.id.action_redo).setIcon(R.drawable.ic_redo_disabled);
      }
    }
    
    @Override
    public boolean onOptionsItemSelected(MenuItem item) {
      switch (item.getItemId()) {
        case R.id.action_undo:
          mModel.undoCommand(mGame);
          return true;
        case R.id.action_redo:
          mModel.redoCommand(mGame);
          return true;
        default:
          return super.onOptionsItemSelected(item);
      }
    }
    
    public void onGameUpdate(Game game) {
      Log.e("dthurn", ">>>>> onGameUpdate " + game);
      mGame = game;
      mGameView.updateGame(game);
      getActivity().invalidateOptionsMenu();
    }

    @Override
    public void addCommand(Command command) {
      mModel.addCommand(mGame, command);
    }

    @Override
    public boolean isLegalCommand(Command command) {
      return mModel.couldSubmitCommand(mGame, command);
    }
}