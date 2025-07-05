import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'flutter_roomplan_platform_interface.dart';

/// An implementation of [FlutterRoomplanPlatform] that uses method channels.
class MethodChannelFlutterRoomplan extends FlutterRoomplanPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('flutter_roomplan');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
