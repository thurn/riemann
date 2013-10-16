package ca.thurn.noughts.android;

import android.app.Fragment;
import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;

import com.example.android.navigationdrawerexample.R;

public class NewGameMenuFragment extends Fragment {
  
  public NewGameMenuFragment() {}
  
  @Override
  public View onCreateView(LayoutInflater inflater, ViewGroup container,
          Bundle savedInstanceState) {
      View menu = inflater.inflate(
          R.layout.fragment_new_game_menu, container, false);
      return menu;
  }

}
