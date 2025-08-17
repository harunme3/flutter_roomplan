import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'flutter_roomplan_platform_interface.dart';

/// An implementation of [FlutterRoomplanPlatform] that uses method channels.
class MethodChannelFlutterRoomplan extends FlutterRoomplanPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('rkg/flutter_roomplan');

  VoidCallback? _captureFinishedHandler;
  VoidCallback? _addMoreRoomsHandler;
  VoidCallback? _scanCancelHandler;
  void Function(String errorCode, String errorMessage)? _errorDetectionHandler;
  bool _isHandlerSetup = false;

  void _setupMethodCallHandler() {
    if (!_isHandlerSetup) {
      methodChannel.setMethodCallHandler((call) async {
        if (call.method == 'onRoomCaptureFinished') {
          _captureFinishedHandler?.call();
        }
        if (call.method == 'onaddMoreRoomsRequested') {
          _addMoreRoomsHandler?.call();
        }
        if (call.method == 'onScanCancelRequested') {
          _scanCancelHandler?.call();
        }
        if (call.method == 'onErrorDetection') {
          final arguments = call.arguments as Map<String, dynamic>?;
          if (arguments != null) {
            final errorCode = arguments['errorCode'] as String? ?? '';
            final errorMessage = arguments['errorMessage'] as String? ?? '';
            _errorDetectionHandler?.call(errorCode, errorMessage);
          }
        }
      });
      _isHandlerSetup = true;
    }
  }

  @override
  Future<void> startScan({bool enableMultiRoom = false}) async {
    await methodChannel.invokeMethod<void>('startScan', {
      'enableMultiRoom': enableMultiRoom,
    });
  }

  @override
  void onRoomCaptureFinished(VoidCallback handler) {
    _captureFinishedHandler = handler;
    _setupMethodCallHandler();
  }

  @override
  void onaddMoreRoomsRequested(VoidCallback handler) {
    _addMoreRoomsHandler = handler;
    _setupMethodCallHandler();
  }

  @override
  void onScanCancelRequested(VoidCallback handler) {
    _scanCancelHandler = handler;
    _setupMethodCallHandler();
  }

  @override
  void onErrorDetection(
    void Function(String errorCode, String errorMessage) handler,
  ) {
    _errorDetectionHandler = handler;
    _setupMethodCallHandler();
  }

  @override
  Future<bool> isSupported() async {
    final bool? result = await methodChannel.invokeMethod<bool>('isSupported');
    return result ?? false;
  }

  @override
  Future<bool> isMultiRoomSupported() async {
    final bool? result = await methodChannel.invokeMethod<bool>(
      'isMultiRoomSupported',
    );
    return result ?? false;
  }

  @override
  Future<String?> getUsdzFilePath() async {
    final String? result = await methodChannel.invokeMethod<String>(
      'getUsdzFilePath',
    );
    return result;
  }

  @override
  Future<String?> getJsonFilePath() async {
    final String? result = await methodChannel.invokeMethod<String>(
      'getJsonFilePath',
    );
    return result;
  }
}
