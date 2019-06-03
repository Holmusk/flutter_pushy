package com.holmusk.flutter_pushy;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry.Registrar;

import android.util.Log;
import android.content.SharedPreferences;
import android.content.Context;
import android.content.pm.PackageManager;
import android.preference.PreferenceManager;
import android.support.v4.content.ContextCompat;
import android.support.v4.app.ActivityCompat;
import android.Manifest.permission;

import me.pushy.sdk.Pushy;

/** FlutterPushyPlugin */
public class FlutterPushyPlugin implements MethodCallHandler {
  /** Plugin registration. */
  private final MethodChannel channel;
  private final Registrar registrar;

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

  /// Plugin constructor
  private FlutterPushyPlugin(Registrar registrar, MethodChannel channel) {
    this.registrar = registrar;
    this.channel = channel;
  }

  /// Method handler
  @Override
  public void onMethodCall(final MethodCall call, final Result result) {
    if (call.method.equals("registerDevice")) {
      /// Register device only if write external storage permission is granted
      /// to prevent multiple token registered from same device
      /// Pushy billed per device based!
      try {
        String deviceToken = Pushy.register(this.registrar.activeContext());
        saveDeviceToken(deviceToken);
        result.success(deviceToken);
      } catch (Exception e) {
        String stackTrace = Log.getStackTraceString(e); 
        result.success(stackTrace);
      }
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
  private String getDeviceToken() {
    return getSharedPreferences().getString("deviceToken", null);
  }

  private void saveDeviceToken(String deviceToken) {
    getSharedPreferences().edit().putString("deviceToken", deviceToken).commit();
  }

  private SharedPreferences getSharedPreferences() {
    return PreferenceManager.getDefaultSharedPreferences(this.registrar.activeContext());
  }
}
