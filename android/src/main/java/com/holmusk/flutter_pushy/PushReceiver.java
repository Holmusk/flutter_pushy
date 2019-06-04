package com.holmusk.flutter_pushy;

import me.pushy.sdk.Pushy;
import android.content.Intent;
import android.content.Context;
import android.content.BroadcastReceiver;
import android.support.v4.content.LocalBroadcastManager;
import android.util.Log;


public class PushReceiver extends BroadcastReceiver {

    public static final String ACTION_REMOTE_MESSAGE =
        "com.holmusk.plugin.pushymessaging.NOTIFICATION";
    public static final String EXTRA_REMOTE_MESSAGE = "notification";

    @Override
    public void onReceive(Context context, Intent intent) {
        Log.d("Receive", intent.getExtras().toString());
        Intent newIntent = new Intent(ACTION_REMOTE_MESSAGE);
        newIntent.putExtras(intent);
        LocalBroadcastManager.getInstance(context).sendBroadcast(newIntent);

        /// HOW TO SHOW NOTIFICATION ????
    }
}