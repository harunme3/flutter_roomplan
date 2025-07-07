import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_roomplan/payloads.dart';
import 'flutter_roomplan_platform_interface.dart';

/// An implementation of [FlutterRoomplanPlatform] that uses method channels.
class MethodChannelFlutterRoomplan extends FlutterRoomplanPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('rkg/flutter_roomplan');

  CaptureFinishedHandler? _captureFinishedHandler;
  bool _isHandlerSetup = false;

  void _setupMethodCallHandler() {
    if (!_isHandlerSetup) {
      methodChannel.setMethodCallHandler((call) async {
        if (call.method == 'onRoomCaptureFinished') {
          String jsonResult = call.arguments;
          _captureFinishedHandler?.call(jsonResult);
        }
      });
      _isHandlerSetup = true;
    }
  }

  @override
  Future<void> startScan() async {
    await methodChannel.invokeMethod<void>('startScan');
  }

  @override
  void onRoomCaptureFinished(CaptureFinishedHandler handler) {
    _captureFinishedHandler = handler;
    _setupMethodCallHandler();
  }

  @override
  Future<bool> isSupported() async {
    final bool? result = await methodChannel.invokeMethod<bool>('isSupported');
    return result ?? false;
  }

  @override
  Future<String?> getUsdzFilePath() async {
    final String? result = await methodChannel.invokeMethod<String>(
      'getUsdzFilePath',
    );
    return result;
  }
}
