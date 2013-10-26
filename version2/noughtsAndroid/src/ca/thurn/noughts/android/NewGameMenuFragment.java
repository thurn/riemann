package ca.thurn.noughts.android;

import android.app.Fragment;
import android.app.ListFragment;
import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ArrayAdapter;
import android.widget.ListView;
import android.widget.TextView;

public class NewGameMenuFragment extends ListFragment {
  
  public NewGameMenuFragment() {}
  
  private static final int NUM_ENTRIES = 5;
  private static final int INVITE_VIA_FACEBOOK = 0;
  private static final int PLAY_VS_COMPUTER = 1;
  private static final int LOCAL_MULTIPLAYER = 2;
  private static final int INVITE_VIA_EMAIL = 3;
  private static final int CANCEL = 4;
  
  @Override
  public void onActivityCreated(Bundle savedInstanceState) {
    super.onActivityCreated(savedInstanceState);
    
    final Integer[] values = new Integer[NUM_ENTRIES];
    values[INVITE_VIA_FACEBOOK] = R.string.invite_via_facebook;
    values[PLAY_VS_COMPUTER] = R.string.play_vs_computer;
    values[LOCAL_MULTIPLAYER] = R.string.local_multiplayer;
    values[INVITE_VIA_EMAIL] = R.string.invite_via_email;
    values[CANCEL] = R.string.cancel;
    
    final Integer[] icons = new Integer[NUM_ENTRIES];
    icons[INVITE_VIA_FACEBOOK] = R.drawable.ic_facebook_invite;
    icons[PLAY_VS_COMPUTER] = R.drawable.ic_vs_computer;
    icons[LOCAL_MULTIPLAYER] = R.drawable.ic_local_multiplayer;
    icons[INVITE_VIA_EMAIL] = R.drawable.ic_email_invite;
    icons[CANCEL] = R.drawable.ic_cancel;
    
    final LayoutInflater inflater = getActivity().getLayoutInflater();
    ArrayAdapter<Integer> adapter = new ArrayAdapter<Integer>(getActivity(),
        R.layout.new_game_menu_item, values) {
      @Override
      public View getView (int position, View convertView, ViewGroup parent) {
        TextView view = (TextView)inflater.inflate(
            R.layout.new_game_menu_item, null);
        view.setText(values[position]);
        view.setCompoundDrawablesWithIntrinsicBounds(icons[position], 0, 0, 0);
        return view;
      }
    };
    getActivity().setTitle(R.string.new_game);
    setListAdapter(adapter);
  }

  @Override
  public void onListItemClick(ListView listView, View view, int position, long rowId) {
    switch (position) {
      case LOCAL_MULTIPLAYER: {
        Fragment fragment = new GameFragment();
        Bundle args = new Bundle();
        args.putBoolean(GameFragment.ARG_SHOULD_CREATE_GAME, true);
        args.putBoolean(GameFragment.ARG_LOCAL_MULTIPLAYER, true);
        fragment.setArguments(args);
        ((MainActivity)getActivity()).switchToFragment(fragment, true);
        break;
      }
      case CANCEL: {
        getActivity().onBackPressed();
        break;
      }
      default: {
        throw new RuntimeException("Unexpected position: " + position);
      }
    }
  }

}
