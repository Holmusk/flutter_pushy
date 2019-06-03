import Flutter
import UIKit
import Pushy

public class SwiftFlutterPushyPlugin: NSObject, FlutterPlugin {
  
  var _channel: FlutterMethodChannel
  var _pushy: Pushy
  
  init(channel: FlutterMethodChannel) {
    _channel = channel
    _pushy = Pushy(UIApplication.shared)
  }
  
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "com.holmusk.flutter_pushy",
                                       binaryMessenger: registrar.messenger())
    let instance = SwiftFlutterPushyPlugin(channel: channel)
    instance.setNotificationHandler()
    registrar.addMethodCallDelegate(instance, channel: channel) 
  }

  private func setNotificationHandler() {
    _pushy.setNotificationHandler({ [weak self](data, completionHandler) in
      print("Received notification: \(data)")
      self?._channel.invokeMethod("onMessage", arguments: data)
    })
  }
  
  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    let method = call.method
    
    switch method {
    case "registerDevice":
      _pushy.register({ (error, deviceToken) in
        if error != nil {
          result("\(error!)")
        } else {
          UserDefaults.standard.set(deviceToken, forKey: "pushyToken")
          result(deviceToken)
        }
      })
    case "configure": result(nil)
    case "getToken": result(UserDefaults.standard.string(forKey: "pushyToken"))
    default: result(FlutterMethodNotImplemented)
    }
  }
}
