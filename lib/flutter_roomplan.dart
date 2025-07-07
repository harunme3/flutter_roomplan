import 'package:flutter_roomplan/payloads.dart';
import 'flutter_roomplan_platform_interface.dart';

class FlutterRoomplan {
  Future<void> startScan() {
    return FlutterRoomplanPlatform.instance.startScan();
  }

  void onRoomCaptureFinished(CaptureFinishedHandler handler) {
    FlutterRoomplanPlatform.instance.onRoomCaptureFinished(handler);
  }

  Future<bool> isSupported() {
    return FlutterRoomplanPlatform.instance.isSupported();
  }
}
