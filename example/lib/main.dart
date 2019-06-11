import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    _fetchToken();
    _pushy.configure(onMessage: (data) {
      print('DATA ON MESSAGE: $data');
      setState(() => _data = data.toString());
    }, onResume: (data) {
      print('DATA ON RESUME: $data');
      setState(() => _data = data.toString());
    },
     onRegisterFail: (err) {
       print('FAILED TO REGISTER DEVICE ${err.toString()}');
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
