package ca.thurn.noughts.android;

import android.app.Fragment;
import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.View.OnClickListener;
import android.view.ViewGroup;
import android.widget.Button;

public class NewGamePromoFragment extends Fragment {
  
  @Override
  public View onCreateView(LayoutInflater inflater, ViewGroup container,
          Bundle savedInstanceState) {
      View view = inflater.inflate(R.layout.fragment_new_game_promo, container, false);
      Button newGameButton = (Button) view.findViewById(R.id.new_game_button);
      newGameButton.setOnClickListener(new OnClickListener() {
        @Override
        public void onClick(View v) {
          ((MainActivity)getActivity()).switchToFragment(new NewGameMenuFragment(), true);  
        }
      });
      return view;
  }
  
}
