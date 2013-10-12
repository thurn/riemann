package ca.thurn.noughts.android

import android.support.v4.app.FragmentActivity
import android.support.v4.app.Fragment
import android.os.Bundle

abstract class SingleFragmentActivity extends FragmentActivity {
  protected abstract def Fragment createFragment();
  
  override onCreate(Bundle savedInstanceState) {
  	super.onCreate(savedInstanceState)
  	setContentView(R.layout.activity_fragment)
  	val fm = getSupportFragmentManager()
  	var fragment = fm.findFragmentById(R.id.fragmentContainer)
  	if (fragment == null) {
  		fragment = createFragment()
  		fm.beginTransaction().add(R.id.fragmentContainer, fragment).commit()
  	}
  }
}