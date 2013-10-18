package ca.thurn.noughts.android;

import android.app.Fragment;
import android.os.Bundle;
import android.support.v4.app.FragmentActivity;


public abstract class SingleFragmentActivity extends FragmentActivity {

  protected abstract Fragment createFragment();
  
  @Override
  public void onCreate(Bundle savedInstanceState) {
    super.onCreate(savedInstanceState);
  }
  
}
