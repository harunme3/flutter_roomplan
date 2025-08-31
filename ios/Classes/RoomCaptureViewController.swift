import UIKit
import RoomPlan
import Flutter
import ARKit
import AVFoundation



/// Comprehensive error types for RoomPlan operations with detailed debugging information
@available(iOS 16.0, *)
enum RoomPlanError: Error {
    case unsupportedVersion
    case roomPlanNotSupported
    case cameraPermissionDenied
    case cameraPermissionNotDetermined
    case cameraPermissionUnknown
    case arKitNotSupported
    case insufficientHardware
    case lowPowerMode
    case insufficientStorage
    case sessionInProgress
    case sessionNotRunning
    case worldTrackingFailed
    case memoryPressure
    case backgroundModeActive
    case deviceOverheating
    case networkRequired
    case processingFailed(String)
    case dataCorrupted(String)
    case exportFailed(String)
    case timeout(String)
    
    /// Error code for Flutter communication
    var code: String {
        switch self {
        case .unsupportedVersion:
            return "unsupported_version"
        case .roomPlanNotSupported:
            return "roomplan_not_supported"
        case .cameraPermissionDenied:
            return "camera_permission_denied"
        case .cameraPermissionNotDetermined:
            return "camera_permission_not_determined"
        case .cameraPermissionUnknown:
            return "camera_permission_unknown"
        case .arKitNotSupported:
            return "arkit_not_supported"
        case .insufficientHardware:
            return "insufficient_hardware"
        case .lowPowerMode:
            return "low_power_mode"
        case .insufficientStorage:
            return "insufficient_storage"
        case .sessionInProgress:
            return "session_in_progress"
        case .sessionNotRunning:
            return "session_not_running"
        case .worldTrackingFailed:
            return "world_tracking_failed"
        case .memoryPressure:
            return "memory_pressure"
        case .backgroundModeActive:
            return "background_mode_active"
        case .deviceOverheating:
            return "device_overheating"
        case .networkRequired:
            return "network_required"
        case .processingFailed:
            return "processing_failed"
        case .dataCorrupted:
            return "data_corrupted"
        case .exportFailed:
            return "export_failed"
        case .timeout:
            return "timeout"
        }
    }
    
    /// Human-readable error message
    var message: String {
        switch self {
        case .unsupportedVersion:
            return "iOS 16.0 or later is required for RoomPlan functionality."
        case .roomPlanNotSupported:
            return "RoomPlan is not supported on this device. A LiDAR sensor is required."
        case .cameraPermissionDenied:
            return "Camera access has been denied. Please enable camera permission in Settings."
        case .cameraPermissionNotDetermined:
            return "Camera permission has not been requested. Please grant camera access when prompted."
        case .cameraPermissionUnknown:
            return "Camera permission status is unknown. Please check app permissions in Settings."
        case .arKitNotSupported:
            return "ARKit is not supported on this device. World tracking capability is required."
        case .insufficientHardware:
            return "This device lacks the necessary hardware for room scanning. A LiDAR sensor or ARKit scene reconstruction is required."
        case .lowPowerMode:
            return "Room scanning is disabled while Low Power Mode is active. Please disable Low Power Mode in Settings."
        case .insufficientStorage:
            return "Insufficient storage space available. At least 100MB of free space is required for room scanning."
        case .sessionInProgress:
            return "A room scanning session is already in progress. Please complete or cancel the current session before starting a new one."
        case .sessionNotRunning:
            return "No room scanning session is currently running. Please start a session before attempting to stop it."
        case .worldTrackingFailed:
            return "World tracking failed. Please ensure adequate lighting and try scanning in a different area."
        case .memoryPressure:
            return "The device is experiencing memory pressure. Please close other apps and try again."
        case .backgroundModeActive:
            return "Room scanning cannot continue while the app is in the background."
        case .deviceOverheating:
            return "The device is overheating. Please let it cool down before continuing room scanning."
        case .networkRequired:
            return "A network connection is required for this operation."
        case .processingFailed(let details):
            return "Failed to process scan data: \(details)"
        case .dataCorrupted(let details):
            return "Scan data appears to be corrupted: \(details)"
        case .exportFailed(let details):
            return "Failed to export scan results: \(details)"
        case .timeout(let operation):
            return "The operation '\(operation)' timed out. Please try again."
        }
    }
    
    /// Additional debugging details
    var details: String? {
        switch self {
        case .unsupportedVersion:
            return "Current iOS version: \(UIDevice.current.systemVersion). Minimum required: 16.0"
        case .roomPlanNotSupported:
            return "Device model: \(UIDevice.current.model). RoomCaptureSession.isSupported: \(RoomCaptureSession.isSupported)"
        case .cameraPermissionDenied, .cameraPermissionNotDetermined, .cameraPermissionUnknown:
            return "Current camera authorization status: \(AVCaptureDevice.authorizationStatus(for: .video).debugDescription)"
        case .arKitNotSupported:
            return "ARWorldTrackingConfiguration.isSupported: \(ARWorldTrackingConfiguration.isSupported)"
        case .insufficientHardware:
            let supportsSceneReconstruction = ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh)
            return "Scene reconstruction support: \(supportsSceneReconstruction), Device model: \(getDeviceModel())"
        case .lowPowerMode:
            return "Low Power Mode enabled: \(ProcessInfo.processInfo.isLowPowerModeEnabled)"
        case .insufficientStorage:
            return "Available storage: \(getAvailableStorageString())"
        case .memoryPressure:
            return "Available memory: \(getAvailableMemoryString())"
        case .deviceOverheating:
            return "Thermal state: \(ProcessInfo.processInfo.thermalState.debugDescription)"
        case .processingFailed(let details), .dataCorrupted(let details), .exportFailed(let details), .timeout(let details):
            return details
        default:
            return nil
        }
    }
    
    /// Recovery suggestions for the user
    var recoverySuggestion: String? {
        switch self {
        case .unsupportedVersion:
            return "Update your device to iOS 16.0 or later to use room scanning."
        case .roomPlanNotSupported:
            return "Use a device with a LiDAR sensor (iPhone 12 Pro or newer Pro models, iPad Pro with LiDAR)."
        case .cameraPermissionDenied:
            return "Go to Settings > Privacy & Security > Camera and enable access for this app."
        case .cameraPermissionNotDetermined:
            return "Grant camera permission when prompted to enable room scanning."
        case .arKitNotSupported:
            return "Use a newer device that supports ARKit world tracking."
        case .insufficientHardware:
            return "Use a device with LiDAR sensor or better ARKit capabilities."
        case .lowPowerMode:
            return "Go to Settings > Battery and turn off Low Power Mode."
        case .insufficientStorage:
            return "Free up at least 100MB of storage space and try again."
        case .sessionInProgress:
            return "Complete or cancel the current scanning session before starting a new one."
        case .worldTrackingFailed:
            return "Ensure good lighting conditions and try scanning a different area with more distinct features."
        case .memoryPressure:
            return "Close other apps and restart the room scanning process."
        case .backgroundModeActive:
            return "Return to the app to continue room scanning."
        case .deviceOverheating:
            return "Let your device cool down for a few minutes before continuing."
        default:
            return "Please try again or contact support if the issue persists."
        }
    }
}


// MARK: - Helper Functions

private func getDeviceModel() -> String {
    var systemInfo = utsname()
    uname(&systemInfo)
    return withUnsafePointer(to: &systemInfo.machine) {
        $0.withMemoryRebound(to: CChar.self, capacity: 1) {
            String(cString: $0)
        }
    }
}

private func getAvailableStorageString() -> String {
    do {
        let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let values = try documentDirectory.resourceValues(forKeys: [.volumeAvailableCapacityKey])
        let bytes = values.volumeAvailableCapacity ?? 0
        return ByteCountFormatter.string(fromByteCount: Int64(bytes), countStyle: .file)
    } catch {
        return "Unknown"
    }
}

private func getAvailableMemoryString() -> String {
    let physicalMemory = ProcessInfo.processInfo.physicalMemory
    return ByteCountFormatter.string(fromByteCount: Int64(physicalMemory), countStyle: .memory)
}

// MARK: - Extensions for debugging

extension AVAuthorizationStatus {
    var debugDescription: String {
        switch self {
        case .authorized: return "authorized"
        case .denied: return "denied"
        case .notDetermined: return "notDetermined"
        case .restricted: return "restricted"
        @unknown default: return "unknown"
        }
    }
}

extension ProcessInfo.ThermalState {
    var debugDescription: String {
        switch self {
        case .nominal: return "nominal"
        case .fair: return "fair"
        case .serious: return "serious"
        case .critical: return "critical"
        @unknown default: return "unknown"
        }
    }
}


 public class RoomCaptureViewController: UIViewController, RoomCaptureViewDelegate, RoomCaptureSessionDelegate {

    public var isMultiRoomModeEnabled: Bool = false
    private var isScanning = false
    private var roomCaptureView: RoomCaptureView!
    private var roomCaptureSessionConfig = RoomCaptureSession.Configuration()
    private var currentCapturedRoom: CapturedRoom?

    // load multiple capturedRoom results to capturedRoomArray
    var capturedRoomArray: [CapturedRoom] = []

    
    public  var usdzFilePath: String?
    public  var jsonFilePath: String?

    private let finishButton = UIButton(type: .system)
    private let scanOtherRoomsButton = UIButton(type: .system)
    private let activityIndicator = UIActivityIndicatorView(style: .large)
    private let cancelButton = UIButton(type: .system)
    private let doneButton = UIButton(type: .system)

    public override func viewDidLoad() {
        super.viewDidLoad()
        performDeviceCompatibilityCheck()
        resetScanningSession()
        setupUI()
        setupRoomCaptureView()
        activityIndicator.stopAnimating()
        // Clean up old files first
        cleanupOldScanFiles()
    }

    public static func isSupported() -> Bool {
        if #available(iOS 16.0, *) {
            return RoomCaptureSession.isSupported
        }
        return false
    }


    // MARK: - Error Handling
    
    private func handleError(_ error: RoomPlanError) {
        print("RoomPlan Error: \(error.message)")
        if let details = error.details {
            print("Details: \(details)")
        }
        
        notifyFlutterError(code: error.code, message: error.message, details: error.details, recoverySuggestion: error.recoverySuggestion)
    }


    // Enhanced Flutter error notification - Thread-safe version
    private func notifyFlutterError(code: String, message: String, details: String? = nil, recoverySuggestion: String? = nil) {
        // Ensure we're on the main thread when calling Flutter
        DispatchQueue.main.async {
            guard let controller = UIApplication.shared.delegate?.window??.rootViewController as? FlutterViewController else {
                print("Failed to get FlutterViewController for error notification")
                return
            }

            let channel = FlutterMethodChannel(name: "rkg/flutter_roomplan", binaryMessenger: controller.binaryMessenger)
            
            var arguments: [String: Any] = [
                "errorCode": code,
                "errorMessage": message
            ]
            
            if let details = details {
                arguments["errorDetails"] = details
            }
            
            if let recoverySuggestion = recoverySuggestion {
                arguments["recoverySuggestion"] = recoverySuggestion
            }
 
            channel.invokeMethod("onErrorDetection", arguments: arguments)
            }
        }

    private func performDeviceCompatibilityCheck() {
        do {
            try performPreflightChecks()
            // If checks pass, continue with scanning
        } catch let error as RoomPlanError {
            print("Device compatibility check failed with error: \(error)")
            handleError(error)  
            return
        } catch {
            print("An unexpected error occurred: \(error)")
            let roomPlanError = classifyError(error)
            handleError(roomPlanError) 
            return
        }
    }

  /// Performs comprehensive pre-flight checks before starting a scan
  private func performPreflightChecks() throws {
    // Check iOS version
    guard #available(iOS 16.0, *) else {
      throw RoomPlanError.unsupportedVersion
    }
    
    // Check RoomPlan availability
    guard RoomCaptureSession.isSupported else {
      throw RoomPlanError.roomPlanNotSupported
    }
    
    // Check camera permission
    let cameraAuthStatus = AVCaptureDevice.authorizationStatus(for: .video)
    switch cameraAuthStatus {
    case .denied, .restricted:
      throw RoomPlanError.cameraPermissionDenied
    case .notDetermined:
      throw RoomPlanError.cameraPermissionNotDetermined
    case .authorized:
      break
    @unknown default:
      throw RoomPlanError.cameraPermissionUnknown
    }
    
    // Check ARKit availability
    guard ARWorldTrackingConfiguration.isSupported else {
      throw RoomPlanError.arKitNotSupported
    }
    
    // Check device capabilities
    let hasRequiredFeatures = ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) || isLiDARDevice()
    guard hasRequiredFeatures else {
      throw RoomPlanError.insufficientHardware
    }
    
    // Check system resources
    if ProcessInfo.processInfo.isLowPowerModeEnabled {
      throw RoomPlanError.lowPowerMode
    }
    
    // Check available storage (need at least 100MB for scan data)
    let freeSpace = try getAvailableStorage()
    if freeSpace < 100 * 1024 * 1024 { // 100MB in bytes
      throw RoomPlanError.insufficientStorage
    }
  }
  
  /// Gets available storage space in bytes
  private func getAvailableStorage() throws -> Int64 {
    let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    let values = try documentDirectory.resourceValues(forKeys: [.volumeAvailableCapacityKey])
    return Int64(values.volumeAvailableCapacity ?? 0)
  }

  
   /// Classifies native errors into specific RoomPlanError types
  private func classifyError(_ error: Error) -> RoomPlanError {
    let errorDescription = error.localizedDescription.lowercased()

    print("ErrorTest description: \(errorDescription)")
    print("ErrorTest details: \(error)")
    
    // Check for specific error patterns
    if errorDescription.contains("world tracking") || errorDescription.contains("not available") {
      return .worldTrackingFailed
    } else if errorDescription.contains("memory") || errorDescription.contains("exceeded") {
      return .memoryPressure
    } else if errorDescription.contains("permission") || errorDescription.contains("camera") {
      return .cameraPermissionDenied
    } else if errorDescription.contains("background") {
      return .backgroundModeActive
    } else if errorDescription.contains("thermal") || errorDescription.contains("overheat") {
      return .deviceOverheating
    } else if errorDescription.contains("timeout") {
      return .timeout("Room scanning session")
    } else if errorDescription.contains("corrupt") || errorDescription.contains("invalid") {
      return .dataCorrupted(error.localizedDescription)
    } else {
      return .processingFailed(error.localizedDescription)
    }
  }


/// Detects LiDAR capability using multiple methods for better accuracy
  private func detectLiDAR() -> Bool {
    let supportsSceneReconstruction = ARWorldTrackingConfiguration.supportsSceneReconstruction(
      .mesh)
    let hasLidarByModel = isLiDARDevice()

    return supportsSceneReconstruction || hasLidarByModel
  }

  /// Checks if the current device model supports LiDAR
  private func isLiDARDevice() -> Bool {
    var systemInfo = utsname()
    uname(&systemInfo)
    let modelCode = withUnsafePointer(to: &systemInfo.machine) {
      $0.withMemoryRebound(to: CChar.self, capacity: 1) {
        ptr in String(cString: ptr)
      }
    }

    let model = modelCode

    // iPhone models with LiDAR
    let lidarIPhones = [
      "iPhone13,2", "iPhone13,3", "iPhone13,4",  // iPhone 12 Pro, 12 Pro Max
      "iPhone14,2", "iPhone14,3",  // iPhone 13 Pro, 13 Pro Max
      "iPhone15,2", "iPhone15,3",  // iPhone 14 Pro, 14 Pro Max
      "iPhone16,1", "iPhone16,2",  // iPhone 15 Pro, 15 Pro Max
      "iPhone17,1", "iPhone17,2",  // iPhone 16 Pro, 16 Pro Max
    ]

    // iPad models with LiDAR
    let lidarIPads = [
      "iPad8,9", "iPad8,10", "iPad8,11", "iPad8,12",  // iPad Pro 11" (4th gen), 12.9" (4th gen)
      "iPad13,4", "iPad13,5", "iPad13,6", "iPad13,7", "iPad13,8", "iPad13,9", "iPad13,10",
      "iPad13,11",  // iPad Pro 11" (5th gen), 12.9" (5th gen)
      "iPad14,3", "iPad14,4", "iPad14,5", "iPad14,6",  // iPad Pro 11" (6th gen), 12.9" (6th gen)
    ]

    return lidarIPhones.contains(model) || lidarIPads.contains(model)
  }

    // Replace the existing button configuration in setupUI() method
    private func setupUI() {
        view.backgroundColor = .white

        // Configure Finish Button - Filled style
        finishButton.setTitle("Finish", for: .normal)
        finishButton.isEnabled = false
        finishButton.isHidden = true
        finishButton.alpha = 0.0
        finishButton.backgroundColor = UIColor(red: 75/255.0, green: 58/255.0, blue: 47/255.0, alpha: 1.0)
        finishButton.setTitleColor(.white, for: .normal)
        finishButton.layer.cornerRadius = 12
        finishButton.addTarget(self, action: #selector(finishAndReturnResult), for: .touchUpInside)

        // Configure Scan Other Rooms Button - Outlined style (only show on iOS 17.0+)
        scanOtherRoomsButton.setTitle("Scan Other Rooms", for: .normal)
        scanOtherRoomsButton.isEnabled = false
        scanOtherRoomsButton.isHidden = true
        scanOtherRoomsButton.alpha = 0.0
        scanOtherRoomsButton.backgroundColor = UIColor.clear
        scanOtherRoomsButton.setTitleColor(UIColor(red: 75/255.0, green: 58/255.0, blue: 47/255.0, alpha: 1.0), for: .normal)
        scanOtherRoomsButton.layer.cornerRadius = 12
        scanOtherRoomsButton.layer.borderWidth = 2.0
        scanOtherRoomsButton.layer.borderColor = UIColor(red: 75/255.0, green: 58/255.0, blue: 47/255.0, alpha: 1.0).cgColor
        scanOtherRoomsButton.addTarget(self, action: #selector(scanOtherRooms), for: .touchUpInside)

        // Configure Cancel and Done Buttons
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.addTarget(self, action: #selector(cancelScanning), for: .touchUpInside)

        doneButton.setTitle("Done", for: .normal)
        doneButton.addTarget(self, action: #selector(doneScanning), for: .touchUpInside)

        // Add subviews
        [finishButton, scanOtherRoomsButton, cancelButton, doneButton, activityIndicator].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }

        setupConstraints()
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            cancelButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            cancelButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),

            doneButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            doneButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),

            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])

        // Set up button constraints based on iOS version and multi-room mode
        if #available(iOS 17.0, *), isMultiRoomModeEnabled {
            // iOS 17.0+ with multi-room: Show both buttons side by side
            NSLayoutConstraint.activate([
                finishButton.trailingAnchor.constraint(equalTo: view.centerXAnchor, constant: -10),
                finishButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -40),
                finishButton.widthAnchor.constraint(equalToConstant: 120),
                finishButton.heightAnchor.constraint(equalToConstant: 44),

                scanOtherRoomsButton.leadingAnchor.constraint(equalTo: view.centerXAnchor, constant: 10),
                scanOtherRoomsButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -40),
                scanOtherRoomsButton.widthAnchor.constraint(equalToConstant: 160),
                scanOtherRoomsButton.heightAnchor.constraint(equalToConstant: 44),
            ])
        } else {
            // iOS 16.0 or single room mode: Only show finish button centered
            NSLayoutConstraint.activate([
                finishButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                finishButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -40),
                finishButton.widthAnchor.constraint(equalToConstant: 120),
                finishButton.heightAnchor.constraint(equalToConstant: 44),
            ])
        }
    }

    private func setupRoomCaptureView() {
        roomCaptureView = RoomCaptureView(frame: .zero)
        roomCaptureView.captureSession.delegate = self
        roomCaptureView.delegate = self
        roomCaptureView.translatesAutoresizingMaskIntoConstraints = false
        view.insertSubview(roomCaptureView, at: 0)

        NSLayoutConstraint.activate([
            roomCaptureView.topAnchor.constraint(equalTo: view.topAnchor),
            roomCaptureView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            roomCaptureView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            roomCaptureView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startSession()
    }

    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopSession()
    }

    private func startSession() {

        isScanning = true
        roomCaptureView.captureSession.run(configuration: roomCaptureSessionConfig)
        
        // Hide Finish button
        finishButton.isHidden = true
        finishButton.alpha = 0.0

        // Hide scan other rooms button (only relevant for iOS 17.0+ with multi-room)
        if #available(iOS 17.0, *), isMultiRoomModeEnabled {
            scanOtherRoomsButton.isHidden = true
            scanOtherRoomsButton.alpha = 0.0
        }

        // Show Done button again (in case it was hidden before)
        doneButton.isHidden = false
        doneButton.alpha = 1.0
    }

    private func stopSession() {
        isScanning = false
        
        // Use appropriate stop method based on iOS version
        if #available(iOS 17.0, *) {
            roomCaptureView.captureSession.stop(pauseARSession: !isMultiRoomModeEnabled)
        } else {
            roomCaptureView.captureSession.stop()
        }

        // Show Finish button
        finishButton.isHidden = false
        UIView.animate(withDuration: 0.3) {
            self.finishButton.alpha = 1.0
        }

        // Show scan other rooms button only for iOS 17.0+ with multi-room enabled
        if #available(iOS 17.0, *), isMultiRoomModeEnabled {
            scanOtherRoomsButton.isHidden = false
            UIView.animate(withDuration: 0.3) {
                self.scanOtherRoomsButton.alpha = 1.0
            }
        }

        // Hide Done button
        UIView.animate(withDuration: 0.3) {
            self.doneButton.alpha = 0.0
        } completion: { _ in
            self.doneButton.isHidden = true
        }
    }

    // ADDED: New method to handle scanning additional rooms in multi-room mode (iOS 17.0+ only)
    @objc private func scanOtherRooms() {
        // This method should only be called on iOS 17.0+ with multi-room mode
        guard #available(iOS 17.0, *), isMultiRoomModeEnabled else {
            return
        }
        
        // Reset the current room scanning state
        currentCapturedRoom = nil
        
        // Hide the buttons and start a new scanning session
        finishButton.isEnabled = false
        scanOtherRoomsButton.isEnabled = false
        
        UIView.animate(withDuration: 0.3) {
            self.finishButton.alpha = 0.0
            self.scanOtherRoomsButton.alpha = 0.0
        } completion: { _ in
            self.finishButton.isHidden = true
            self.scanOtherRoomsButton.isHidden = true
            self.startSession()
        }
    }

    public func captureView(shouldPresent roomDataForProcessing: CapturedRoomData, error: Error?) -> Bool {
        return true
    }

    public func captureView(didPresent processedResult: CapturedRoom, error: Error?) {
        if let error = error {
            print("Room capture error: \(error)")
            let roomPlanError = classifyError(error)
            handleError(roomPlanError)
            return
        }
        currentCapturedRoom = processedResult
        capturedRoomArray.append(processedResult)
        finishButton.isEnabled = true
        
        // Only enable scan other rooms button on iOS 17.0+ with multi-room mode
        if #available(iOS 17.0, *), isMultiRoomModeEnabled {
            scanOtherRoomsButton.isEnabled = true
        }
        
        activityIndicator.stopAnimating()
        
    }
  // MARK: - RoomCaptureSessionDelegate
    public func captureSession(_ session: RoomCaptureSession, didAdd room: CapturedRoom) {
        print("Room captured successfully")
    }
    
    public func captureSession(_ session: RoomCaptureSession, didChange room: CapturedRoom) {
        print("Room data updated")
    }
    
    public func captureSession(_ session: RoomCaptureSession, didProvide instruction: RoomCaptureSession.Instruction) {
        print("Instruction provided: \(instruction)")
    }
    
    public func captureSession(_ session: RoomCaptureSession, didStartWith configuration: RoomCaptureSession.Configuration) {
        print("Capture session started")
    }
    
    public func captureSession(_ session: RoomCaptureSession, didEndWith data: CapturedRoomData, error: Error?) {
        if let error = error {
        print("Capture session ended with error: \(error)")
        let roomPlanError = classifyError(error)
        handleError(roomPlanError)
        cancelScanning()
        } else {
            print("Capture session ended successfully")
        }
    }

    public func captureSession(_ session: RoomCaptureSession, didFailWith error: Error) {
      print("Capture session failed with error: \(error)")
      let roomPlanError = classifyError(error)
      handleError(roomPlanError)   
    }
 // MARK: - RoomCaptureSessionDelegate

    @objc private func doneScanning() {
        if isScanning {
            stopSession()
        } else {
            cancelScanning()
        }        
        activityIndicator.startAnimating()
    }

   @objc public func cancelScanning() {
        print("Cancel scanning")
        if isScanning {
            if #available(iOS 17.0, *) {
                roomCaptureView.captureSession.stop(pauseARSession: !isMultiRoomModeEnabled)
            } else {
                roomCaptureView.captureSession.stop()
            }
        }
        resetScanningSession()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.dismiss(animated: true)
        }
    }


      private func exportToJSON() async -> Bool {
        guard let currentCapturedRoom = currentCapturedRoom else { 
            print("No captured room data to export")
            notifyFlutterError(
            code: "no_data",
            message: "No captured room data available for export",
            details: "Current captured room is nil",
            recoverySuggestion: "Please complete a room scan before attempting to export"
           )
            return false 
        }
        
        do {
            let jsonEncoder = JSONEncoder()
            jsonEncoder.outputFormatting = [.prettyPrinted]
            
            // For iOS 16.0, export single room; for iOS 17.0+ with multi-room, export array
            let dataToExport: Data
            if #available(iOS 17.0, *), isMultiRoomModeEnabled {
                dataToExport = try jsonEncoder.encode(capturedRoomArray)
            } else {
                dataToExport = try jsonEncoder.encode(currentCapturedRoom)
            }
            
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let roomScansFolder = documentsPath.appendingPathComponent("RoomDataScans")
            
            // Create the RoomDataScans directory if it doesn't exist
            if !FileManager.default.fileExists(atPath: roomScansFolder.path) {
                try FileManager.default.createDirectory(at: roomScansFolder, withIntermediateDirectories: true)
            }
            
            let fileName = "room_scan_\(Int(Date().timeIntervalSince1970)).json"
            let fileURL = roomScansFolder.appendingPathComponent(fileName)
            
            try dataToExport.write(to: fileURL)
            self.jsonFilePath = fileURL.path
            
            print("Successfully exported JSON file to: \(fileURL.path)")
            return true
            
        } catch {
            print("Failed to export JSON file: \(error)")
            return false
        }
    }


    private func exportToUSDZ() async -> Bool {
        guard let currentCapturedRoom = currentCapturedRoom else {
            print("No captured room data to export")
            notifyFlutterError(
            code: "no_data",
            message: "No captured room data available for export",
            details: "Current captured room is nil",
            recoverySuggestion: "Please complete a room scan before attempting to export"
        )
            return false
        }

        if #available(iOS 17.0, *) {
            do {
                let structureBuilder = StructureBuilder(options: [.beautifyObjects])
                let capturedStructure: CapturedStructure
                
                // Use merge API for multi-room in iOS 17.0+, single room for others
                if isMultiRoomModeEnabled {
                    capturedStructure = try await structureBuilder.capturedStructure(from: capturedRoomArray)
                } else {
                    capturedStructure = try await structureBuilder.capturedStructure(from: [currentCapturedRoom])
                }

                let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                let roomScansFolder = documentsPath.appendingPathComponent("RoomDataScans")

                if !FileManager.default.fileExists(atPath: roomScansFolder.path) {
                    try FileManager.default.createDirectory(at: roomScansFolder, withIntermediateDirectories: true)
                }

                let fileName = "room_scan_\(Int(Date().timeIntervalSince1970)).usdz"
                let fileURL = roomScansFolder.appendingPathComponent(fileName)

                try capturedStructure.export(to: fileURL)
                self.usdzFilePath = fileURL.path
                
                print("Successfully exported USDZ file to: \(fileURL.path)")
                return true
                
            } catch {
                print("Failed to export USDZ file: \(error)")
                return false
            }
        } else if #available(iOS 16.0, *) {
            // For iOS 16.0, use the single room export method
            do {
                let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                let roomScansFolder = documentsPath.appendingPathComponent("RoomDataScans")

                if !FileManager.default.fileExists(atPath: roomScansFolder.path) {
                    try FileManager.default.createDirectory(at: roomScansFolder, withIntermediateDirectories: true)
                }

                let fileName = "room_scan_\(Int(Date().timeIntervalSince1970)).usdz"
                let fileURL = roomScansFolder.appendingPathComponent(fileName)

                try currentCapturedRoom.export(to: fileURL)
                self.usdzFilePath = fileURL.path
                
                print("Successfully exported USDZ file to: \(fileURL.path)")
                return true
                
            } catch {
                print("Failed to export USDZ file: \(error)")
                return false
            }
        } else {
            print("USDZ export is only supported on iOS 16.0 or newer")
            return false
        }
    }


    @objc private func finishAndReturnResult() {
        guard let currentCapturedRoom = currentCapturedRoom else {
            notifyFlutterError(
            code: "no_data",
            message: "No captured room data available",
            details: "Current captured room is nil",
            recoverySuggestion: "Please complete a room scan before finishing"
            )   
            cancelScanning()
            return
        }

        // Show activity indicator while exporting
        activityIndicator.startAnimating()
        finishButton.isEnabled = false
        
        if #available(iOS 17.0, *), isMultiRoomModeEnabled {
            scanOtherRoomsButton.isEnabled = false
        }

    Task {
        do {
            // Export both files and wait for completion
            let usdzSuccess = await exportToUSDZ()
            let jsonSuccess = await exportToJSON()
            
            // Only call Flutter after both exports succeed
            await MainActor.run {
                    self.activityIndicator.stopAnimating()
                    
                    if usdzSuccess && jsonSuccess {
                        // Both exports succeeded, notify Flutter
                        if let controller = UIApplication.shared.delegate?.window??.rootViewController as? FlutterViewController {
                            let channel = FlutterMethodChannel(name: "rkg/flutter_roomplan", binaryMessenger: controller.binaryMessenger)
                            channel.invokeMethod("onRoomCaptureFinished", arguments: nil)
                        }
                        print("Export completed successfully")
                        self.dismiss(animated: true)
                    } else {
                        // One or both exports failed
                        print("Export failed - USDZ: \(usdzSuccess), JSON: \(jsonSuccess)")
                        cancelScanning()
                        // You might want to show an alert to the user here
                    }
                    
                    
                }
        } catch {
            await MainActor.run {
                self.activityIndicator.stopAnimating()
                finishButton.isEnabled = true
                if #available(iOS 17.0, *), isMultiRoomModeEnabled {
                    scanOtherRoomsButton.isEnabled = true
                }
                print("Export failed: \(error)")
                // Handle export failure
                cancelScanning()
            }
        }
    }
  }



      private func cleanupOldScanFiles(keepLastCount: Int = 2) {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let roomScansFolder = documentsPath.appendingPathComponent("RoomDataScans")
        
        do {
            if FileManager.default.fileExists(atPath: roomScansFolder.path) {
                let files = try FileManager.default.contentsOfDirectory(at: roomScansFolder, includingPropertiesForKeys: [.creationDateKey])
                
                // Filter only .usdz and .json files
                let scanFiles = files.filter { file in
                    let ext = file.pathExtension.lowercased()
                    return ext == "usdz" || ext == "json"
                }
                
                // Sort by creation date (newest first)
                let sortedFiles = scanFiles.sorted { file1, file2 in
                    guard let date1 = try? file1.resourceValues(forKeys: [.creationDateKey]).creationDate,
                          let date2 = try? file2.resourceValues(forKeys: [.creationDateKey]).creationDate else {
                        return false
                    }
                    return date1 > date2
                }
                
                // Delete files beyond the keep count
                if sortedFiles.count > keepLastCount {
                    let filesToDelete = Array(sortedFiles.dropFirst(keepLastCount))
                    for file in filesToDelete {
                        try FileManager.default.removeItem(at: file)
                    }
                    print("Cleaned up \(filesToDelete.count) old scan files, kept \(min(sortedFiles.count, keepLastCount)) recent files")
                }
            }
        } catch {
            print("Failed to cleanup old scan files: \(error)")
            notifyFlutterError(
            code: "cleanup_failed",
            message: "Failed to cleanup old scan files",
            details: error.localizedDescription,
            recoverySuggestion: "This won't affect scanning functionality, but old files may accumulate"
        )
        }
    }

    private func resetScanningSession() {
        capturedRoomArray.removeAll()
        currentCapturedRoom = nil
        usdzFilePath = nil
        jsonFilePath = nil
    }
}