import Flutter
import UIKit
import RoomPlan

public class FlutterRoomplanPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "rkg/flutter_roomplan", binaryMessenger: registrar.messenger())
    let instance = FlutterRoomplanPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "startScan":
        DispatchQueue.main.async {
        let rootVC = UIApplication.shared.delegate?.window??.rootViewController
        let roomVC = RoomCaptureViewController()
        roomVC.modalPresentationStyle = .fullScreen
        rootVC?.present(roomVC, animated: true, completion: nil)
      }
      result(nil)
    case "isSupported":
      if #available(iOS 16.0, *) {
        result(RoomCaptureSession.isSupported)
      } else {
        result(false)
      }
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
