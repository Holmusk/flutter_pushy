import Flutter
import UIKit
import Pushy

public class SwiftFlutterPushyPlugin: NSObject, FlutterPlugin {
  
  var _channel: FlutterMethodChannel
  var _pushy: Pushy
  var _resumingFromBackground: Bool
  
  init(channel: FlutterMethodChannel) {
    _channel = channel
    _pushy = Pushy(UIApplication.shared)
    _resumingFromBackground = true;
  }
  
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "com.holmusk.flutter_pushy",
                                       binaryMessenger: registrar.messenger())
    let instance = SwiftFlutterPushyPlugin(channel: channel)
    registrar.addMethodCallDelegate(instance, channel: channel)
    registrar.addApplicationDelegate(instance)
    instance.setNotificationHandler()
  }

  private func setNotificationHandler() {
    print("PUSHY NOTIFICATION HANDLER SET")
    _pushy.setNotificationHandler({ [unowned self](data, completionHandler) in
      print("Received notification: \(data) \(self._resumingFromBackground)")
      if self._resumingFromBackground {
        self._channel.invokeMethod("onResume", arguments: data)
       }
      else {
        self._channel.invokeMethod("onMessage", arguments: data)
      }
    })
  }
  
  private func registerPushy() {
    _pushy.register({ [weak self](error, deviceToken) in
      if error == nil {
        UserDefaults.standard.set(deviceToken, forKey: "pushyToken")
        // result(deviceToken)
        self?._channel.invokeMethod("onToken", arguments: deviceToken)
      }
    })
  }
  
  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    let method = call.method
    
    switch method {
    case "registerDevice":
      registerPushy()
      result(nil)
    case "configure": 
      setNotificationHandler()
      result(nil)
    case "getToken": result(UserDefaults.standard.string(forKey: "pushyToken"))
    default: result(FlutterMethodNotImplemented)
    }
  }



  /// APPLICATION DELEGATE
  public func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [AnyHashable : Any] = [:]) -> Bool {
    print("App launched with option: \(launchOptions)")
    registerPushy()
    setNotificationHandler()
    return true
    
  }
  
  public func applicationDidBecomeActive(_ application: UIApplication) {
    _resumingFromBackground = false
    print("app become active \(_resumingFromBackground)")
  }
  
  public func applicationDidEnterBackground(_ application: UIApplication) {
    _resumingFromBackground = true
    print("app move to background \(_resumingFromBackground)")
  }

}
