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

  void onaddMoreRoomsRequested(VoidCallback handler) {
    FlutterRoomplanPlatform.instance.onaddMoreRoomsRequested(handler);
  }

  void onScanCancelRequested(VoidCallback handler) {
    FlutterRoomplanPlatform.instance.onScanCancelRequested(handler);
  }

  /// Register a callback to handle errors during room scanning or processing.
  ///
  /// The callback receives an error code and error message.
  ///
  /// Common error codes include:
  /// - "ROOM_PROCESSING_FAILED": Failed to process room data
  /// - "EXPORT_FAILED": Both USDZ and JSON export failed
  /// - "USDZ_EXPORT_FAILED": USDZ file export failed
  /// - "JSON_EXPORT_FAILED": JSON file export failed
  /// - "EXPORT_EXCEPTION": Unexpected error during export
  void onErrorDetection(
    void Function(String errorCode, String errorMessage) handler,
  ) {
    FlutterRoomplanPlatform.instance.onErrorDetection(handler);
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

  // Clear saved ARWorldMap
  Future<bool> clearArWorldMap() {
    return FlutterRoomplanPlatform.instance.clearArWorldMap();
  }
}
