import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:meta/meta.dart';
import 'package:platform/platform.dart';


/// Event handler types
typedef Future<dynamic> MessageHandler(Map<String, dynamic> message);
typedef Future<String>  TokenHandler(String token);
typedef Future<int>     ErrorHandler(int errorCode );

/// Implementation of pushy messaging API for flutter
///
/// Your app should call [registerDevice] to get a token
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

  
  /// Request write external storage permissions <Android only>
  Future<void> requestWriteExtStoragePermission() async {
    // This is mandatory to prevent multiple token issued for same device.
    if (_platform.isAndroid) {
      return _channel.invokeMethod('requestWriteExtStoragePermission');
    }
  }
  
  /// Get status of write external storage permission <Android only>
  Future<bool> get writeExtStoragePermission async {
    // if not android return true
    if (!_platform.isAndroid) { return true; }
    return _channel.invokeMethod('fetchWriteExtStoragePermission');
  }
    
  /// Sets up [Handlers] for incoming events.
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
  Future<Null> registerDevice() async => await _channel.invokeMethod('registerDevice');

  /// Returns locally stored [token] String
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