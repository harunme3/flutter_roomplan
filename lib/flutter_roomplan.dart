import 'flutter_roomplan_platform_interface.dart';

class FlutterRoomplan {
  Future<void> startScan() {
    return FlutterRoomplanPlatform.instance.startScan();
  }
}
