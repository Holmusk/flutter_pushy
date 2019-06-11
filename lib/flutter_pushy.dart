import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:meta/meta.dart';
import 'package:platform/platform.dart';

typedef Future<dynamic> MessageHandler(Map<String, dynamic> message);
typedef Future<String> TokenHandler(String token);
typedef Future<int> ErrorHandler(int errorCode );

/// Implementation of pushy messaging API for flutter
///
/// Your app should call [requestNotificationPermissions] first
/// then [registerDevice] to get a token
/// then register handles dor incoming messages with [configure]
///
class FlutterPushy {
  factory FlutterPushy() => _instance;

  @visibleForTesting
  FlutterPushy.private(MethodChannel channel, Platform platform,)
      : _channel = channel,
        _platform = platform;

  static final FlutterPushy _instance = 
  FlutterPushy.private(const MethodChannel('com.holmusk.flutter_pushy'), 
                       const LocalPlatform());

  final MethodChannel _channel;
  final Platform      _platform;
  MessageHandler      _onMessage ;
  MessageHandler      _onResume;
  ErrorHandler        _onRegisterFail;
  TokenHandler        _onToken;

  /// Request permission to show notification
  /// Only fire in iOS
  void requestNotificationPermissions() {  
      if (!_platform.isIOS) { return; }
      _channel.invokeMethod('requestPermissions');
  }

  /// Request write external storage permissions
  /// Only fire in android
  /// Necessary so pushy can reuse token 
  /// To prevent multiple token for 1 device
  void requestWriteExtStoragePermission() {
    if (!_platform.isAndroid) { return; }
    _channel.invokeMethod('requestWriteExtStoragePermission');
  }
  
  /// Get status of write external storage permission
  /// for Android OS
  Future<bool> get writeExtStoragePermission async 
    => _channel.invokeMethod('fetchWriteExtStoragePermission');

  /// Sets up [MessageHandler] for incoming messages.
  void configure({
    MessageHandler onMessage, 
    MessageHandler onResume, 
    TokenHandler onToken, 
    ErrorHandler onRegisterFail}) {
      _onToken        = onToken;
      _onMessage      = onMessage;
      _onResume       = onResume;
      _onRegisterFail = onRegisterFail;
      _channel.setMethodCallHandler(_handleMethod);
      _channel.invokeMethod('configure');
  }

  /// Register device to pushy server
  /// and return a token string
  Future<String> registerDevice() async => await _channel.invokeMethod('registerDevice');

  /// Returns locally stored pushy token
  Future<String> getToken() async => await _channel.invokeMethod('getToken');
  
  /// Handle callback from plugin itself
  Future<dynamic> _handleMethod(MethodCall call) async {
    switch (call.method) {
      case 'onMessage':
        return _onMessage(call.arguments.cast<String, dynamic>());
      case 'onResume':
        return _onResume(call.arguments.cast<String, dynamic>());
      case 'onRegisterFail':
        return _onRegisterFail(call.arguments);
      case 'onToken':
        return _onToken(call.arguments);
      default:
        throw UnsupportedError('Unrecognized JSON message');
    }
  }
}

/// Dr Teng's iPhone 3ce0fe63729c5c533c7283