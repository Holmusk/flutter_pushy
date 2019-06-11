package com.holmusk.flutter_pushy;

import io.flutter.plugin.common.FlutterException;
import me.pushy.sdk.Pushy;

import java.util.HashMap;
import java.util.Map;
import java.util.Set;
import java.lang.ref.WeakReference;

import io.flutter.plugin.common.FlutterException;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry.Registrar;
import io.flutter.plugin.common.PluginRegistry.NewIntentListener;

import android.os.AsyncTask;
import android.os.Bundle;

import android.util.Log;
import android.media.RingtoneManager;
import android.graphics.Color;
import android.preference.PreferenceManager;

import android.app.PendingIntent;
import android.app.NotificationManager;

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


public class FlutterPushyPlugin
  extends BroadcastReceiver
  implements MethodCallHandler, NewIntentListener {

  private static final String CLICK_ACTION_VALUE = "PUSHY_NOTIFICATION_CLICK";
  private static final String FLUTTER_CHANNEL = "com.holmusk.flutter_pushy";

  private final MethodChannel channel;
  private final Registrar registrar;

  RegisterDeviceTask _runner;

  /// =====================================================================================
  /// Flutter plugin methods
  /// =====================================================================================
  public static void registerWith(Registrar registrar) {
    final MethodChannel channel = 
      new MethodChannel(registrar.messenger(), FLUTTER_CHANNEL);
    final FlutterPushyPlugin plugin = 
      new FlutterPushyPlugin(registrar, channel);
    channel.setMethodCallHandler(plugin);
    plugin.requestWriteExtStoragePermission();
    Pushy.listen(registrar.activeContext());
    registrar.addNewIntentListener(plugin);
  }

  private FlutterPushyPlugin(Registrar registrar, MethodChannel channel) {
    this.registrar  = registrar;
    this.channel    = channel;
    IntentFilter intentFilter = new IntentFilter();
    intentFilter.addAction(PushReceiver.ACTION_REMOTE_MESSAGE);
    LocalBroadcastManager manager = LocalBroadcastManager.getInstance(registrar.activeContext());
    manager.registerReceiver(this, intentFilter);
  }

  @Override
  public void onMethodCall(final MethodCall call, final Result result) {
    switch (call.method) {
      case "registerDevice":
        registerDevice();
        result.success(null);
        break;
      case "getToken":
        String deviceToken = getDeviceToken();
        result.success(deviceToken);
        break;
      case "configure":
        result.success(null);
        break;
      case "requestWriteExtStoragePermission":
        this.requestWriteExtStoragePermission();
        result.success(null);
        break;
      case "fetchWriteExtStoragePermission":
        final boolean isGranted = isWriteExtStorageGranted();
        result.success(isGranted);
        break;
      default:
        result.notImplemented();
        break;
    }
  }

  /// =====================================================================================
  /// Register device methods
  /// =====================================================================================
  private void registerDevice() {
    // Register device only if write external storage permission is granted
    // to prevent multiple token registered from same device
    // Pushy billed per device based!
    if (isWriteExtStorageGranted()) {
      if (_runner != null) {
        _runner.cancel(true);
      }
      _runner = new RegisterDeviceTask(this);
      _runner.execute();
    } else {
      channel.invokeMethod("onRegisterFail", 401);
    }
  }

  /// =====================================================================================
  /// Write external storage permissions methods
  /// =====================================================================================
  private boolean isWriteExtStorageGranted() {
    return ContextCompat.checkSelfPermission(
            this.registrar.activeContext(), android.Manifest.permission.WRITE_EXTERNAL_STORAGE)
            == PackageManager.PERMISSION_GRANTED;
  }

  /// Request Write External Storage Permission
  private void requestWriteExtStoragePermission() {
    if (!isWriteExtStorageGranted()) {
      ActivityCompat.requestPermissions(this.registrar.activity(),
              new String[]{android.Manifest.permission.READ_EXTERNAL_STORAGE,
                      android.Manifest.permission.WRITE_EXTERNAL_STORAGE}, 0);
    }
  }

  /// =====================================================================================
  ///  Intent receiving methods
  /// =====================================================================================
  @Override
  public void onReceive(Context context, Intent intent) {

    if (intent.getAction() != null
            && !intent.getAction().equals(PushReceiver.ACTION_REMOTE_MESSAGE)) {
      Log.d("Warning", "Received unknown action");
      return;
    }

    String title = intent.getStringExtra("title") != null ?
            intent.getStringExtra("title") :
            "Notification";
    String message = intent.getStringExtra("message") != null ?
            intent.getStringExtra("message") :
            "You receive a notification";

    final Bundle bundle = intent.getExtras();
    if (bundle == null) {
      Log.d("Warning", "Received message without payload");
      return;
    }
    channel.invokeMethod("onMessage", bundleToMap(bundle));

    int NOTIFICATION_ID = 234;
    String CHANNEL_ID = "flutter_pushy";

    Intent nIntent = new Intent(CLICK_ACTION_VALUE);
    nIntent.putExtras(bundle);
    PendingIntent pIntent = PendingIntent.getActivity(context,
            0,
            nIntent,
            PendingIntent.FLAG_UPDATE_CURRENT);

    NotificationCompat.Builder builder =
    new NotificationCompat.Builder(context, CHANNEL_ID)
    .setAutoCancel(true)
    .setSmallIcon(android.R.drawable.ic_dialog_info)
    .setLights(Color.RED, 1000, 1000)
    .setVibrate(new long[]{0, 400, 250, 400})
    .setSound(RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION))
    .setContentTitle(title)
    .setContentText(message)
    .setContentIntent(pIntent);

    Pushy.setNotificationChannel(builder, context);

    NotificationManager manager =
            (NotificationManager) context.getSystemService(Context.NOTIFICATION_SERVICE);
    manager.notify(NOTIFICATION_ID, builder.build());
  }

  @Override
    public boolean onNewIntent(Intent intent) {
      Log.d(intent.getAction(), "On intent received from local notification");

      if (intent.getAction() != null && !intent.getAction().equals(CLICK_ACTION_VALUE)) {
        Log.d("Warning", "Received unknown action");
        return false;
      }

      final Bundle bundle = intent.getExtras();
      if (bundle == null) {
        Log.d("Warning", "Received message without payload");
        return false;
      }
      channel.invokeMethod("onResume", bundleToMap(bundle));
      return true;
    }

  /// =====================================================================================
  ///  Methods to store and fetch token from local preferences
  /// =====================================================================================
  private String getDeviceToken() {
    return getSharedPreferences().getString("deviceToken", null);
  }

  private void saveDeviceToken(String deviceToken) {
    getSharedPreferences().edit().putString("deviceToken", deviceToken).apply();
  }

  private SharedPreferences getSharedPreferences() {
    return PreferenceManager.getDefaultSharedPreferences(this.registrar.activeContext());
  }

  /// =====================================================================================
  /// Register device asynchronous runner
  /// =====================================================================================
  private static class RegisterDeviceTask extends AsyncTask<Void, Void, String> {

    private WeakReference<FlutterPushyPlugin> activityReference;

    RegisterDeviceTask(FlutterPushyPlugin context) {
      activityReference = new WeakReference<>(context);
    }


    @Override
    protected String doInBackground(Void... params) {
      FlutterPushyPlugin activity = activityReference.get();
      if (activity == null) {
        return null;
      }
      try {
        return Pushy.register(activity.registrar.activeContext());
      } catch (Exception e) {
        Log.d("RegisterDeviceTask", e.getMessage());
        return null;
      }
    }

    @Override
    protected void onPostExecute(String result) {
      FlutterPushyPlugin activity = activityReference.get();
      if (activity != null) {
        if (result != null) {
          activity.saveDeviceToken(result);
          activity.channel.invokeMethod("onToken", result);
        } else {
          activity.channel.invokeMethod("onRegisterFail", 500);
        }
      }
    }
  }

  /// =====================================================================================
  /// Bundle to map methods
  /// =====================================================================================
  public static Map<String, Object> bundleToMap(Bundle extras) {
    Map<String, Object> map = new HashMap<>();
    Set<String> ks = extras.keySet();
    for (String key: ks) {
      final Object value = extras.get(key);
      Log.d("DEBUG", "");
      if (value != null) {
        map.put(key, value);
      }
    }
    return map;
  }
}
