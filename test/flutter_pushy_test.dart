// import 'package:test/test.dart';
// import 'package:mockito/mockito.dart';
// import 'package:platform/platform.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_pushy/flutter_pushy.dart';

// void main() {
//   MockMethodChannel mockChannel;
//   FlutterPushy pushy;

//   setUp(() {
//     print('SETUP');
//     mockChannel = MockMethodChannel();
//     pushy       = FlutterPushy.private(mockChannel, FakePlatform(operatingSystem: 'ios'));
//   });

//   test('reguestWriteExternalStoragePermission_IOS', () {
//     pushy.requestWriteExtStoragePermission();
//     verifyNever(mockChannel.setMethodCallHandler(any));
//     verifyNever(mockChannel.invokeMethod('requestWriteExtStoragePermission'));
//   });

//   test('fetchWriteExternalStoragePermission_IOS', () async {
//     final status = await pushy.writeExtStoragePermission;
//     verifyNever(mockChannel.setMethodCallHandler(any));
//     verifyNever(mockChannel.invokeMethod('requestWriteExtStoragePermission'));
//     assert(status, equals(true));
//   });

//   test('reguestWriteExternalStoragePermission_Android', () {
//     pushy = FlutterPushy.private(mockChannel, FakePlatform(operatingSystem: 'android'));
//     pushy.requestWriteExtStoragePermission();
//     verifyNever(mockChannel.setMethodCallHandler(any));
//     verify(mockChannel.invokeMethod('requestWriteExtStoragePermission'));
//   });

//   test('fetchWriteExternalStoragePermission_Android', () async {
//     pushy = FlutterPushy.private(mockChannel, FakePlatform(operatingSystem: 'android'));
//     final bool denied = false;
//     verifyNever(mockChannel.invokeMethod('fetchWriteExtStoragePermission', denied));
//     mockChannel.invokeMethod('fetchWriteExtStoragePermission', denied);
//     verify(mockChannel.invokeMethod('fetchWriteExtStoragePermission', denied));
//     final bool granted = true;
//     verifyNever(mockChannel.invokeMethod('fetchWriteExtStoragePermission', granted));
//     mockChannel.invokeMethod('fetchWriteExtStoragePermission', granted);
//     verify(mockChannel.invokeMethod('fetchWriteExtStoragePermission', granted));
//   });



//   test('registerDevice', () {
//     pushy.registerDevice();
//     verify(mockChannel.invokeMethod('registerDevice'));
//   });

//   test('configure', () {
//     pushy.configure();
//     verify(mockChannel.setMethodCallHandler(any));
//     verify(mockChannel.invokeMethod('configure'));
//   });
// }

// class MockMethodChannel extends Mock implements MethodChannel {}
