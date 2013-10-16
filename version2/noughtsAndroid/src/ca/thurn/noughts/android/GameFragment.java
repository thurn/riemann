package ca.thurn.noughts.android;

import com.example.android.navigationdrawerexample.R;

import android.os.Bundle;
import android.support.v4.app.Fragment;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.TextView;

/**
 * Fragment that appears in the "content_frame", shows a planet
 */
public class GameFragment extends Fragment {
    public static final String ARG_GAME_ID = "game_id";

    public GameFragment() {}

    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container,
            Bundle savedInstanceState) {
        View rootView = inflater.inflate(R.layout.fragment_game, container, false);
        int i = getArguments().getInt(ARG_GAME_ID);
        String planet = getResources().getStringArray(R.array.games_array)[i];
        ((TextView)rootView.findViewById(R.id.game_detail)).setText(planet);
        return rootView;
    }
}