package com.holmusk.flutter_pushy;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry.Registrar;
import io.flutter.plugin.common.PluginRegistry.NewIntentListener;

import java.util.Map;
import java.util.HashMap;
import java.util.Iterator;
import java.util.Set;

import android.os.AsyncTask;
import android.os.Bundle;
import android.util.Log;
import android.media.RingtoneManager;
import android.graphics.Color;
import android.Manifest.permission;
import android.preference.PreferenceManager;

import android.app.Activity;
import android.app.PendingIntent;
import android.app.NotificationManager;
import android.app.NotificationChannel;

import android.content.SharedPreferences;
import android.content.Context;
import android.content.pm.PackageManager;
import android.content.Intent;
import android.content.IntentFilter;
import android.content.BroadcastReceiver;

import android.support.v4.content.ContextCompat;
import android.support.v4.app.ActivityCompat;
import android.support.v4.app.NotificationCompat;
import android.support.v4.content.LocalBroadcastManager;

import me.pushy.sdk.Pushy;

/** FlutterPushyPlugin */
public class FlutterPushyPlugin
  extends BroadcastReceiver
  implements MethodCallHandler, NewIntentListener {
  /** Plugin registration. */
  private final MethodChannel channel;
  private final Registrar registrar;

  private static final String CLICK_ACTION_VALUE = "PUSHY_NOTIFICATION_CLICK";

  /// Register channel and handler
  public static void registerWith(Registrar registrar) {
    final MethodChannel channel = 
      new MethodChannel(registrar.messenger(), "com.holmusk.flutter_pushy");
    final FlutterPushyPlugin plugin = 
      new FlutterPushyPlugin(registrar, channel);
    channel.setMethodCallHandler(plugin);
    /// Automatically request write storage permission
    /// on 1st Usage
    plugin.requestWriteExtStoragePermission();
    Pushy.listen(registrar.activeContext());
    /// Listen for CLICK_ACTION_VALUE
    registrar.addNewIntentListener(plugin);
  }

  /// Plugin constructor
  private FlutterPushyPlugin(Registrar registrar, MethodChannel channel) {
    this.registrar = registrar;
    this.channel = channel;

    IntentFilter intentFilter = new IntentFilter();
    intentFilter.addAction(PushReceiver.ACTION_REMOTE_MESSAGE);
    LocalBroadcastManager manager = LocalBroadcastManager.getInstance(registrar.activeContext());
    manager.registerReceiver(this, intentFilter);
  }




  @Override
  public void onReceive(Context context, Intent intent) {

    // IF ACTION != pushy id then ignore
    String action = intent.getAction();
    if (PushReceiver.ACTION_REMOTE_MESSAGE.equals(action)) {
      Log.d(action, "Received unkown intent action");
      return;
    }

    String title = "Notication";
    String message = "Test Notification";
    if (intent.getStringExtra("message") != null) {
      message = intent.getStringExtra("message");
    }

    int NOTIFICATION_ID = 234;
    String CHANNEL_ID = "flutter_pushy";

    Intent nIntent = new Intent(CLICK_ACTION_VALUE);
    nIntent.putExtras(intent);
    PendingIntent pIntent = PendingIntent.getActivity(context, 0, nIntent, 0);
    
    NotificationCompat.Builder builder = 
    new NotificationCompat.Builder(context)
    .setChannelId(CHANNEL_ID)
    .setAutoCancel(true)
    .setSmallIcon(android.R.drawable.ic_dialog_info)
    .setLights(Color.RED, 1000, 1000)
    .setVibrate(new long[]{0, 400, 250, 400})
    .setSound(RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION))
    .setContentTitle(title)
    .setContentText(message)
    .setContentIntent(pIntent);

    Pushy.setNotificationChannel(builder, context);

    NotificationManager manager = (NotificationManager) context.getSystemService(context.NOTIFICATION_SERVICE);
    manager.notify(NOTIFICATION_ID, builder.build());
  }


  @Override
    public boolean onNewIntent(Intent intent) {
      Log.d(intent.getAction(), "NEW INTENT FROM ONNEWINTENT");
  
      return true;
    }







  /// Check if wirte external storage permission
  /// is granted or not
  private boolean isWriteExtStorageGranted() {
    return ContextCompat.checkSelfPermission(
      this.registrar.activeContext(), android.Manifest.permission.WRITE_EXTERNAL_STORAGE) 
      == PackageManager.PERMISSION_GRANTED;
  }

  /// Request Write External Storage Permission
  private void requestWriteExtStoragePermission() {
    if (!isWriteExtStorageGranted()) {
    ActivityCompat
      .requestPermissions(this.registrar.activity(), 
                          new String[]{android.Manifest.permission.READ_EXTERNAL_STORAGE, 
                                      android.Manifest.permission.WRITE_EXTERNAL_STORAGE}, 
                          0);
    }
  }

  /// Method handler
  @Override
  public void onMethodCall(final MethodCall call, final Result result) {
    if (call.method.equals("registerDevice")) {
      /// Register device only if write external storage permission is granted
      /// to prevent multiple token registered from same device
      /// Pushy billed per device based!
      RegisterDeviceTask runner = new RegisterDeviceTask();
      runner.execute();
      result.success(null);
    } 
    else if (call.method.equals("getToken")) {
      String deviceToken = getDeviceToken();
      result.success(deviceToken);
    }
    else if (call.method.equals("configure")) {
      result.success(null);
    }
    else if (call.method.equals("requestWriteExtStoragePermission")) {
      this.requestWriteExtStoragePermission();
      result.success(null);
    }
    else if (call.method.equals("fetchWriteExtStoragePermission")) {
      final boolean isGranted = isWriteExtStorageGranted();
      result.success(isGranted);
    }
    else {
      result.notImplemented();
     }
  }



  ///  Methods to store and fetch token from local preferences
  /// =====================================================================================
  private String getDeviceToken() {
    return getSharedPreferences().getString("deviceToken", null);
  }

  private void saveDeviceToken(String deviceToken) {
    getSharedPreferences().edit().putString("deviceToken", deviceToken).commit();
  }

  private SharedPreferences getSharedPreferences() {
    return PreferenceManager.getDefaultSharedPreferences(this.registrar.activeContext());
  }

  /// Register device asynchronous runner
  /// =====================================================================================
  private class RegisterDeviceTask extends AsyncTask<Void, Void, String> {
    private String resp;
    @Override
    protected String doInBackground(Void... params) {
      try {
        resp = Pushy.register(registrar.activeContext());
        saveDeviceToken(resp);
      } catch (Exception e) {
        resp = e.getMessage();
      }
      return resp;
    }

    @Override
    protected void onPostExecute(String result) {
      channel.invokeMethod("onToken", result);
    }
  }

  public static Map<String, String> bundleToMap(Bundle extras) {
        Map<String, String> map = new HashMap<String, String>();

        Set<String> ks = extras.keySet();
        Iterator<String> iterator = ks.iterator();
        while (iterator.hasNext()) {
            String key = iterator.next();
            map.put(key, extras.getString(key));
        }//from   www . j  a  v  a  2  s  .co m
        return map;
    }
}
