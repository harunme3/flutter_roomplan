import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'flutter_roomplan_platform_interface.dart';

/// An implementation of [FlutterRoomplanPlatform] that uses method channels.
class MethodChannelFlutterRoomplan extends FlutterRoomplanPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('rkg/flutter_roomplan');

  VoidCallback? _captureFinishedHandler;
  FlutterRoomplanErrorHandler? _errorHandler;
  bool _isHandlerSetup = false;

  void _setupMethodCallHandler() {
    if (!_isHandlerSetup) {
      methodChannel.setMethodCallHandler((call) async {
        if (call.method == 'onRoomCaptureFinished') {
          _captureFinishedHandler?.call();
        } else if (call.method == 'onErrorDetection') {
          debugPrint('Handling onErrorDetection');
          try {
            final arguments = call.arguments;
            if (arguments != null) {
              Map<String, dynamic> args;
              if (arguments is Map<String, dynamic>) {
                args = arguments;
              } else if (arguments is Map) {
                args = Map<String, dynamic>.from(arguments);
              } else {
                debugPrint(
                  'Unexpected arguments type: ${arguments.runtimeType}',
                );
                return;
              }

              final errorCode = args['errorCode'] as String?;
              final errorMessage = args['errorMessage'] as String?;
              final errorDetails = args['errorDetails'] as String?;
              final recoverySuggestion = args['recoverySuggestion'] as String?;

              debugPrint(
                'Error details: code=$errorCode, message=$errorMessage',
              );
              _errorHandler?.call(
                errorCode,
                errorMessage,
                errorDetails,
                recoverySuggestion,
              );
            } else {
              debugPrint('No arguments provided for onErrorDetection');
            }
          } on Exception catch (e) {
            debugPrint('Error in onErrorDetection: $e');
          }
        } else {
          debugPrint('Unknown method call: ${call.method}');
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
  Future<void> stopScan() async {
    await methodChannel.invokeMethod<void>('stopScan');
  }

  @override
  void onRoomCaptureFinished(VoidCallback handler) {
    _captureFinishedHandler = handler;
    _setupMethodCallHandler();
  }

  @override
  void onErrorDetection(FlutterRoomplanErrorHandler handler) {
    _errorHandler = handler;
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
