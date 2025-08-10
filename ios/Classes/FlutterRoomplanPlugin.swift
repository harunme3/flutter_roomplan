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
        let arguments = call.arguments as? [String: Any]
        let enableMultiRoom = arguments?["enableMultiRoom"] as? Bool ?? false

        // Multi-room mode is only supported on iOS 17.0+
        let finalEnableMultiRoom: Bool
        if #available(iOS 17.0, *) {
            finalEnableMultiRoom = enableMultiRoom
        } else {
            finalEnableMultiRoom = false
            if enableMultiRoom {
                print("Multi-room mode requested but only supported on iOS 17.0+. Using single room mode.")
            }
        }

        DispatchQueue.main.async {
        let rootVC = UIApplication.shared.delegate?.window??.rootViewController
        let roomVC = RoomCaptureViewController()
        roomVC.isMultiRoomModeEnabled = finalEnableMultiRoom
        roomVC.modalPresentationStyle = .fullScreen
        rootVC?.present(roomVC, animated: true, completion: nil)
      }
      result(nil)
    case "isSupported":
      result(RoomCaptureViewController.isSupported())
    case "isMultiRoomSupported":
        if #available(iOS 17.0, *) {
            result(RoomCaptureViewController.isSupported())
        } else {
            result(false)
        }
    case "getUsdzFilePath":
      if let roomVC = UIApplication.shared.delegate?.window??.rootViewController?.presentedViewController as? RoomCaptureViewController {
        result(roomVC.usdzFilePath)
      } else {
        result(FlutterError(code: "NO_SCAN", message: "No active room scan found", details: nil))
      }
    case "getJsonFilePath":
      if let roomVC = UIApplication.shared.delegate?.window??.rootViewController?.presentedViewController as? RoomCaptureViewController {
        result(roomVC.jsonFilePath)
      } else {
        result(FlutterError(code: "NO_SCAN", message: "No active room scan found", details: nil))
      }
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
