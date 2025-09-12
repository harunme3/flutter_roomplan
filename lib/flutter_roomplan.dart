import 'package:flutter/foundation.dart';
import 'flutter_roomplan_platform_interface.dart';

class FlutterRoomplan {
  Future<void> startScan({bool enableMultiRoom = false}) {
    return FlutterRoomplanPlatform.instance.startScan();
  }

  void onRoomCaptureFinished(VoidCallback handler) {
    FlutterRoomplanPlatform.instance.onRoomCaptureFinished(handler);
  }

  void onErrorDetection(FlutterRoomplanErrorHandler handler) {
    FlutterRoomplanPlatform.instance.onErrorDetection(handler);
  }

  Future<bool> isSupported() {
    return FlutterRoomplanPlatform.instance.isSupported();
  }

  /// Returns the file path of the exported USDZ file from the last room scan.
  /// Returns null if no scan has been completed or if the export failed.
  Future<String?> getUsdzFilePath() {
    return FlutterRoomplanPlatform.instance.getUsdzFilePath();
  }
}
