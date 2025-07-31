import 'package:flutter_roomplan/payloads.dart';
import 'flutter_roomplan_platform_interface.dart';

class FlutterRoomplan {
  Future<void> startScan({bool enableMultiRoom = false}) {
    return FlutterRoomplanPlatform.instance.startScan(enableMultiRoom: enableMultiRoom);
  }

  void onRoomCaptureFinished(CaptureFinishedHandler handler) {
    FlutterRoomplanPlatform.instance.onRoomCaptureFinished(handler);
  }

  Future<bool> isSupported() {
    return FlutterRoomplanPlatform.instance.isSupported();
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
