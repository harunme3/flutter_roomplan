import Flutter
import UIKit

public class FlutterRoomplanPlugin: NSObject, FlutterPlugin {

  // Store reference to the room capture view controller
  private static var sharedRoomVC: RoomCaptureViewController?

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
              
              // Check if we have an existing room capture view controller
              if let existingRoomVC = FlutterRoomplanPlugin.sharedRoomVC {
                  // Reuse existing instance - preserve array data
                  existingRoomVC.isMultiRoomModeEnabled = finalEnableMultiRoom
                  existingRoomVC.view.isHidden = false
                  
                  // If it's not already presented, present it
                  if existingRoomVC.presentingViewController == nil {
                      rootVC?.present(existingRoomVC, animated: true, completion: nil)
                  }
              } else {
                  // Create new instance only if none exists
                  let roomVC = RoomCaptureViewController()
                  roomVC.isMultiRoomModeEnabled = finalEnableMultiRoom
                  roomVC.modalPresentationStyle = .fullScreen
                  
                  // Store reference to preserve state
                  FlutterRoomplanPlugin.sharedRoomVC = roomVC
                  
                  rootVC?.present(roomVC, animated: true, completion: nil)
              }
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
      if let roomVC = FlutterRoomplanPlugin.sharedRoomVC {
        result(roomVC.usdzFilePath)
      } else {
        result(FlutterError(code: "NO_SCAN", message: "No active room scan found", details: nil))
      }
    case "getJsonFilePath":
      if let roomVC = FlutterRoomplanPlugin.sharedRoomVC {
        result(roomVC.jsonFilePath)
      } else {
        result(FlutterError(code: "NO_SCAN", message: "No active room scan found", details: nil))
      }
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
