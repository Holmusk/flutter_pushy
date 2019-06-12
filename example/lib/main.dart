import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_pushy/flutter_pushy.dart';
import 'package:platform/platform.dart';


void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _data;
  String _token = '';
  final _pushy = FlutterPushy();
  bool _isLoading = false;

  FlutterLocalNotificationsPlugin _localPlugin = FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _fetchToken();
    _configurePushy();
    _configureLocalNotification();
  }

  void _configureLocalNotification() {
    var initializationSettingsAndroid =
    AndroidInitializationSettings('app_icon');
    
    var initializationSettingsIOS = IOSInitializationSettings(
    onDidReceiveLocalNotification: _onDidReceiveLocalNotification);
    
    var initializationSettings = InitializationSettings(
    initializationSettingsAndroid, initializationSettingsIOS);
    
    _localPlugin.initialize(initializationSettings,
    onSelectNotification: _onSelectNotification);
  }

  Future<void> onDidReceiveLocalNotification(
    int id,
   String title, 
   String body, 
   String payload) async {
     print('RECEIVE LOCAL NOTIF PAYLOAD : $payload');  
  }
  Future<void> _onDidReceiveLocalNotification(
    int id,
   String title, 
   String body, 
   String payload) async {
     print('RECEIVE LOCAL NOTIF PAYLOAD : $payload');  
  }

  Future<void> _onSelectNotification(String payload) async {
    print('HANDLE LOCAL NOTIFICATION SELECTION $payload');
  }

  Future<void> showNotification(String body, String payload) async {
    print('SHOW LOCAL NOTIFICATION $body $payload');
    var androidPlatformChannelSpecifics = AndroidNotificationDetails(
        'com.holmusk.glycoleap.inAppLocal',
        'inAppLocal',
        'In App Local notification',
        importance: Importance.Max,
        priority: Priority.High);
    var iOSPlatformChannelSpecifics = IOSNotificationDetails();
    var platformChannelSpecifics = NotificationDetails(
        androidPlatformChannelSpecifics, iOSPlatformChannelSpecifics);
    await _localPlugin.show(0, 'GLYCO', body, platformChannelSpecifics,
        payload: payload);
  }

  void _configurePushy() {
    _pushy.configure(
      onMessage: (data) {
      print('DATA ON MESSAGE: $data');
      setState(() => _data = data.toString());
      if (LocalPlatform().isIOS) {
        final body = data['message'] ?? 'Notification';
        showNotification(body, data.toString());
      }
    }, onResume: (data) {
      print('DATA ON RESUME: $data');
      setState(() => _data = data.toString());
    },
     onRegisterFail: (err) {
       print('FAILED TO REGISTER DEVICE WITH CODE: $err');
     }
    , onToken: (token) {
      print('found new Token: $token');
      setState(() => _token = token);
    });
  }

  void _fetchToken() async {
    final token = await FlutterPushy().getToken();
    print('Token: $token');
    setState(() => _token = token);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Pushy Test'),
        ),
        body: LocalPlatform().isIOS
            ? _iOScontent(context)
            : _iAndroidDontent(context),
      ),
    );
  }

  Widget _iOScontent(BuildContext context) {
    return _isLoading
        ? Center(child: CircularProgressIndicator())
        : Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: <Widget>[
                RaisedButton(
                  child: Text('Register Device'),
                  onPressed: () => _pushy.registerDevice(),
                ),
                SizedBox(height: 24.0),
                _tokenWidget(context),
                SizedBox(height: 24.0),
                (_data == null)
                    ? Container()
                    : Text(
                        'Last Data Sent:\n${_data.toString()}',
                        textAlign: TextAlign.center,
                      ),
              ],
            ),
          );
  }

  Widget _iAndroidDontent(BuildContext context) {
    return _isLoading
        ? Center(child: CircularProgressIndicator())
        : Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: <Widget>[
                RaisedButton(
                  child: Text('Request write permission'),
                  onPressed: () {
                    _pushy.requestWriteExtStoragePermission();
                  },
                ),
                RaisedButton(
                  child: Text('Get write permission'),
                  onPressed: () async {
                    final granted = await _pushy.writeExtStoragePermission;
                    print(
                        'Write external storage permission: ${granted ? 'yes' : 'no'}');
                  },
                ),
                RaisedButton(
                  child: Text('Register Device'),
                  onPressed: () => _pushy.registerDevice(),
                ),
                SizedBox(height: 24.0),
                _tokenWidget(context),
                SizedBox(height: 24.0),
                (_data == null)
                    ? Container()
                    : Text(
                        'Last Data Sent:\n${_data.toString()}',
                        textAlign: TextAlign.center,
                      ),
              ],
            ),
          );
  }

  Widget _tokenWidget(BuildContext context) {
    return (_token == null)
        ? Container()
        : Text(
            'Device Token:\n$_token',
            textAlign: TextAlign.center,
          );
  }
}
