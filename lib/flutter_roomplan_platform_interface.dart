import 'package:flutter_roomplan/payloads.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'flutter_roomplan_method_channel.dart';

abstract class FlutterRoomplanPlatform extends PlatformInterface {
  /// Constructs a FlutterRoomplanPlatform.
  FlutterRoomplanPlatform() : super(token: _token);

  static final Object _token = Object();

  static FlutterRoomplanPlatform _instance = MethodChannelFlutterRoomplan();

  /// The default instance of [FlutterRoomplanPlatform] to use.
  ///
  /// Defaults to [MethodChannelFlutterRoomplan].
  static FlutterRoomplanPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [FlutterRoomplanPlatform] when
  /// they register themselves.
  static set instance(FlutterRoomplanPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<void> startScan({bool enableMultiRoom = false}) {
    throw UnimplementedError('startScan() has not been implemented.');
  }

  void onRoomCaptureFinished(CaptureFinishedHandler handler) {
    throw UnimplementedError(
      'onRoomCaptureFinished() has not been implemented.',
    );
  }

  Future<bool> isSupported() {
    throw UnimplementedError('isSupported() has not been implemented.');
  }

  Future<String?> getUsdzFilePath() {
    throw UnimplementedError('getUsdzFilePath() has not been implemented.');
  }

  Future<String?> getJsonFilePath() {
    throw UnimplementedError('getJsonFilePath() has not been implemented.');
  }
}
