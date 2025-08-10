import 'package:flutter/foundation.dart';
import 'flutter_roomplan_platform_interface.dart';

class FlutterRoomplan {
  Future<void> startScan({bool enableMultiRoom = false}) {
    return FlutterRoomplanPlatform.instance.startScan(
      enableMultiRoom: enableMultiRoom,
    );
  }

  void onRoomCaptureFinished(VoidCallback handler) {
    FlutterRoomplanPlatform.instance.onRoomCaptureFinished(handler);
  }

  void onScanOtherRoomsRequested(VoidCallback handler) {
    FlutterRoomplanPlatform.instance.onScanOtherRoomsRequested(handler);
  }

  Future<bool> isSupported() {
    return FlutterRoomplanPlatform.instance.isSupported();
  }

  Future<bool> isMultiRoomSupported() {
    return FlutterRoomplanPlatform.instance.isMultiRoomSupported();
  }

  /// Returns the file path of the exported USDZ file from the last room scan.
  /// Returns null if no scan has been completed or if the export failed.
  Future<String?> getUsdzFilePath() {
    return FlutterRoomplanPlatform.instance.getUsdzFilePath();
  }

  /// Returns the file path of the exported JSON file from the last room scan.
  /// Returns null if no scan has been completed or if the export failed.
  Future<String?> getJsonFilePath() {
    return FlutterRoomplanPlatform.instance.getJsonFilePath();
  }
}
