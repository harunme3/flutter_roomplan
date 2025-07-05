import 'package:flutter_roomplan/types.dart';

import 'flutter_roomplan_platform_interface.dart';

class FlutterRoomplan {
  Future<void> startScan() {
    return FlutterRoomplanPlatform.instance.startScan();
  }

  void onRoomCaptureFinished(CaptureFinishedHandler handler) {
    FlutterRoomplanPlatform.instance.onRoomCaptureFinished(handler);
  }
}
