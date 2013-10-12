package ca.thurn.noughts.android

class GameActivity extends SingleFragmentActivity {
  
  override protected createFragment() {
    return new GameFragment()
  }
  
}