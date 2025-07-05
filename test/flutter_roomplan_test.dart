import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_roomplan/flutter_roomplan.dart';
import 'package:flutter_roomplan/flutter_roomplan_platform_interface.dart';
import 'package:flutter_roomplan/flutter_roomplan_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockFlutterRoomplanPlatform
    with MockPlatformInterfaceMixin
    implements FlutterRoomplanPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final FlutterRoomplanPlatform initialPlatform = FlutterRoomplanPlatform.instance;

  test('$MethodChannelFlutterRoomplan is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelFlutterRoomplan>());
  });

  test('getPlatformVersion', () async {
    FlutterRoomplan flutterRoomplanPlugin = FlutterRoomplan();
    MockFlutterRoomplanPlatform fakePlatform = MockFlutterRoomplanPlatform();
    FlutterRoomplanPlatform.instance = fakePlatform;

    expect(await flutterRoomplanPlugin.getPlatformVersion(), '42');
  });
}
