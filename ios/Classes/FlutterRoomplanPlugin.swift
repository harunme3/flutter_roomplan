import Flutter
import UIKit

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
      result(RoomCaptureViewController.isSupported())
    case "getUsdzFilePath":
      if let roomVC = UIApplication.shared.delegate?.window??.rootViewController?.presentedViewController as? RoomCaptureViewController {
        result(roomVC.usdzFilePath)
      } else {
        result(FlutterError(code: "NO_SCAN", message: "No active room scan found", details: nil))
      }
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
