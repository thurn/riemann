package ca.thurn.noughts.android

import android.support.v4.app.Fragment
import ca.thurn.noughts.shared.Game
import android.os.Bundle
import android.view.ViewGroup
import android.view.LayoutInflater

class GameFragment extends Fragment {
  Game mGame
  
  override onCreate(Bundle savedInstanceState) {
    super.onCreate(savedInstanceState)
    mGame = new Game()
  }
  
  override onCreateView(LayoutInflater inflater, ViewGroup parent, Bundle savedInstanceState) {
    val view = inflater.inflate(R.layout.game_fragment, parent, false)
    return view
  }
}