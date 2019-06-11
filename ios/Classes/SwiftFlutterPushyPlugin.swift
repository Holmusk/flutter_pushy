import Flutter
import UIKit
import Pushy

public class SwiftFlutterPushyPlugin: NSObject, FlutterPlugin {
  
  static let PUSHY_TOKEN_KEY = "pushyToken"
  static let FLUTTER_CHANNEL = "com.holmusk.flutter_pushy"
  
  var _pushy                  : Pushy
  var _channel                : FlutterMethodChannel
  var _resumingFromBackground : Bool
  
  init(channel: FlutterMethodChannel) {
    _channel  = channel
    _pushy    = Pushy(UIApplication.shared)
    _resumingFromBackground = false;
  }
  
  /// Pushy methods
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: FLUTTER_CHANNEL,
                                       binaryMessenger: registrar.messenger())
    let instance = SwiftFlutterPushyPlugin(channel: channel)
    registrar.addMethodCallDelegate(instance, channel: channel)
    registrar.addApplicationDelegate(instance)
  }
  
  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    let method = call.method
    switch method {
    case "registerDevice":
      registerPushy()
      result(nil)
    case "configure":
      result(nil)
    case "getToken":
      result(UserDefaults.standard.string(forKey: SwiftFlutterPushyPlugin.PUSHY_TOKEN_KEY))
    default:
      result(FlutterMethodNotImplemented)
    }
  }
  
  /// Private methods
  private func registerPushy() {
    _pushy.register({ [unowned self](error, deviceToken) in
      if error == nil {
        UserDefaults.standard.set(deviceToken,
                                  forKey: SwiftFlutterPushyPlugin.PUSHY_TOKEN_KEY)
        self._channel.invokeMethod("onToken", arguments: deviceToken)
      } else {
        self._channel.invokeMethod("onRegisterFail", arguments: 500)
      }
    })
  }
  
  private func setNotificationHandler() {
    _pushy.setNotificationHandler({ [unowned self](data, completionHandler) in
      self._resumingFromBackground ?
        self._channel.invokeMethod("onResume", arguments: data) :
        self._channel.invokeMethod("onMessage", arguments: data)
      completionHandler(UIBackgroundFetchResult.newData)
    })
  }
  
  /// Application delegates
  public func application(_ application: UIApplication,
                          didFinishLaunchingWithOptions launchOptions: [AnyHashable : Any] = [:]) -> Bool {
    setNotificationHandler()
    return true
  }
  
  public func applicationDidBecomeActive(_ application: UIApplication) {
    _resumingFromBackground = false
    // Reset badge number once app goes to foreground
    application.applicationIconBadgeNumber = 1;
    application.applicationIconBadgeNumber = 0;
  }
  
  public func applicationDidEnterBackground(_ application: UIApplication) {
    _resumingFromBackground = true
  }
}
