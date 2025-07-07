import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_roomplan/types.dart';

import 'flutter_roomplan_platform_interface.dart';

/// An implementation of [FlutterRoomplanPlatform] that uses method channels.
class MethodChannelFlutterRoomplan extends FlutterRoomplanPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('rkg/flutter_roomplan');

  CaptureFinishedHandler? _captureFinishedHandler;

  @override
  Future<void> startScan() async {
    methodChannel.setMethodCallHandler((call) async {
      if (call.method == 'onRoomCaptureFinished') {
        String jsonResult = call.arguments;
        // Do something with the JSON
        _captureFinishedHandler?.call(jsonResult);
      }
    });
    await methodChannel.invokeMethod<void>('startScan');
  }

  @override
  void onRoomCaptureFinished(CaptureFinishedHandler handler) {
    _captureFinishedHandler = handler;
  }

  @override
  Future<bool> isSupported() async {
    final bool? result = await methodChannel.invokeMethod<bool>('isSupported');
    return result ?? false;
  }
}
