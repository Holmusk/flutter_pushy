# Pushy messaging for Flutter

A Flutter plugin to use push notification delivery service from [PUSHY](https://pushy.me/).

With this plugin, your Flutter app can receive and process push notifications on Android and iOS.
Read [Pushy SDK documentation](https://pushy.me/docs) to get good understanding about how it works.

*Note*: This plugin is still under development, and some APIs might not be available yet.
[FEEDBACK](https://github.com/holmusk/flutter_pushy/issues) and [PULL REQUEST](https://github.com/holmusk/flutter_pushy/pulls) are most welcome!

## Usage
To use this plugin, add `flutter_pushy` as a [dependency in your pubspec.yaml file](https://flutter.io/platform-plugins/).

```
dependencies:
    flutter_pushy: ^1.0.0
```

## Getting Started
Check out the `example` directory for a sample app using Pushy.
Sign up on [Pushy website](https://pushy.me), to access dashboard page and create an app. 

## Android Integration

To integrate your plugin intot the Android part of your app, follow these steps:
1. Using Pushy console [create Android app](https://pushy.me/docs/android/create-app) in dashboard.
2. (Optional, but recommended) If want to be notified in your app (via onResume) when user clicks on a notification in the system tray, include the following code to your `AndroidManifest.xml`, inside activity tag.
```
<application>
    <activity ...>
        ...
        <intent-filter>
            <action android:name="PUSHY_NOTIFICATION_CLICK" />
            <category android:name="android.intent.category.DEFAULT" />
        </intent-filter>
    </activity>
</application>
```

## iOS Integration

To integrate your plugin into the iOS part of your app, follow these steps:
1. Using Pushy console [create Android app](https://pushy.me/docs/ios/create-app) in dashboard.
2. [Enable push notification capability](https://pushy.me/docs/ios/enable-capability) in Xcode project.
3. Setup [APNS authentication](https://pushy.me/docs/ios/setup-apns-auth) and export it's authentication key.

## Dart/Flutter Integration

From your Dart code, you need to import the plugin and instatiate it:
```
import 'package:flutter_pushy/flutter_pushy.dart';
final FlutterPushy _pushy = FlutterPushy();
```
> On Android this will bring up write external storage permissions for user to confirm. This is mandatory to prevent multiple token issued for same device for each installation.

### Register your device to Pushy server. 
> `_pushy.registerDevice()`. 

IOS - This will bring up a permissions dialog for user to confirm on. It's no-op on Android (*if write external storage permission is granted). Pushy will issue a token for each device once device registered, which will be handled in next step.

### Configure pushy plugin.
> `_pushy.configure(...)`
1. **onMessage**
triggered when on notification received when app is in foreground.
In iOS you must handle in-app notification manually. (ex. use LocalNotification or Dialog widget)
2. **onResume**
    Triggered on user tap on push notification when app is in background.
3. **onToken**
    Triggered if device registered successfully to Pushy server.
4. **onRegisterFail**
    Triggered if device registration failed, return `500` (network error) or `401` (write external storage permissions is denied - Android only).
    
```
_pushy.configure(
      onMessage: (data) {
      print('DATA ON MESSAGE: $data');
      if (LocalPlatform().isIOS) {
        ...
      }
      ...
    }, onResume: (data) {
      print('DATA ON RESUME: $data');
      ...
    },
     onRegisterFail: (err) {
     print('failed to register device with code :$err')
       ...
     }
    , onToken: (token) {
      print('found new Token: $token');
      ...
    });
```
## Sending Test Messages

Refer to Pushy [dashboard](https://dashboard.pushy.me/apps/<APP_ID>/send) or startup guide on [Android](https://pushy.me/docs/android/send-test-notification) or [iOS](https://pushy.me/docs/ios/send-test-notification) to send test notification.
> Make sure to set **Content-Available** as true for iOS


