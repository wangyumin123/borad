import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/services.dart';

import './model/model.dart';
import 'gen/protos/protos.pb.dart' as proto;

// ignore: avoid_classes_with_only_static_members
/// Barcode scanner plugin
/// Simply call `var barcode = await BarcodeScanner.scan()` to scan a barcode
class BarcodeScanner {
  /// If the user has granted the access to the camera this code is returned.
  static const cameraAccessGranted = 'PERMISSION_GRANTED';

  /// If the user has not granted the access to the camera this code is thrown.
  static const cameraAccessDenied = 'PERMISSION_NOT_GRANTED';

  /// The method channel
  static const MethodChannel _channel =
      MethodChannel('de.mintware.barcode_scan');

  /// The event channel
  static const EventChannel _eventChannel =
      EventChannel('de.mintware.barcode_scan/events');

  /// Starts the camera for scanning the barcode, shows a preview window and
  /// returns the barcode if one was scanned.
  /// Can throw an exception.
  /// See also [cameraAccessDenied]
  static Future<ScanResult> scan({
    ScanOptions options = const ScanOptions(),
  }) async {
    assert(options != null);
    if (Platform.isIOS) {
      return _doScan(options);
    }
    print('1111111111sacn');
    var events = _eventChannel.receiveBroadcastStream();
    var completer = Completer<ScanResult>();

    print('22222222222222sacn');
    StreamSubscription subscription;
    subscription = events.listen((event) async {
      if (event is String) {
        if (event == cameraAccessGranted) {
          print('23333333333333sacn');
          subscription.cancel();
          completer.complete(await _doScan(options));
        } else if (event == cameraAccessDenied) {
          print('44444444444444sacn');
          subscription.cancel();
          completer.completeError(PlatformException(code: event));
        }
      }
    });

    print('55555555555555sacn');
    var permissionsRequested =
        await _channel.invokeMethod('requestCameraPermission');

    if (permissionsRequested) {
      print('26666666666666666sacn');
      return completer.future;
    } else {
      print('27777777777777777sacn');
      subscription.cancel();
      return _doScan(options);
    }
  }

  static Future<ScanResult> _doScan(ScanOptions options) async {
    print('111111111sss1sacn');
    var config = proto.Configuration()
          ..useCamera = options.useCamera
          ..restrictFormat.addAll(options.restrictFormat)
          ..autoEnableFlash = options.autoEnableFlash
          ..strings.addAll(options.strings)
          ..android = (proto.AndroidConfiguration()
                ..useAutoFocus = options.android.useAutoFocus
                ..aspectTolerance = options.android.aspectTolerance
              /**/)
        /**/;
    var buffer = await _channel.invokeMethod('scan', config?.writeToBuffer());
    var tmpResult = proto.ScanResult.fromBuffer(buffer);
    return ScanResult(
      format: tmpResult.format,
      formatNote: tmpResult.formatNote,
      rawContent: tmpResult.rawContent,
      type: tmpResult.type,
    );
  }

  /// Returns the number of cameras which are available
  /// Use n-1 as the index of the camera which should be used.
  static Future<int> get numberOfCameras {
    return _channel.invokeMethod('numberOfCameras');
  }
}
