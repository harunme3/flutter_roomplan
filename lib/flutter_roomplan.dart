
import 'flutter_roomplan_platform_interface.dart';

class FlutterRoomplan {
  Future<String?> getPlatformVersion() {
    return FlutterRoomplanPlatform.instance.getPlatformVersion();
  }
}
