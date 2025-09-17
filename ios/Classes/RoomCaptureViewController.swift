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

@available(iOS 16.0, *)
public class RoomCaptureViewController: UIViewController, RoomCaptureViewDelegate, RoomCaptureSessionDelegate {

    private var isScanning = false
    private var roomCaptureView: RoomCaptureView!
    private var roomCaptureSessionConfig = RoomCaptureSession.Configuration()
    private var currentCapturedRoom: CapturedRoom?

    public var usdzFilePath: String?

    private let finishButton = UIButton(type: .system)
    private let activityIndicator = UIActivityIndicatorView(style: .large)
    private let cancelButton = UIButton(type: .system)
    private let doneButton = UIButton(type: .system)

    public override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupRoomCaptureView()
        activityIndicator.stopAnimating()
        // Clean up old files first
        deleteAllScanFiles()
    }

    public static func isSupported() -> Bool {
        if #available(iOS 16.0, *) {
            return RoomCaptureSession.isSupported
        }
        return false
    }

    private func handleError(_ error: RoomPlanError) {
        print("RoomPlan Error: \(error.message)")
        if let details = error.details {
            print("Details: \(details)")
        }
        
        notifyFlutterError(code: error.code, message: error.message, details: error.details, recoverySuggestion: error.recoverySuggestion)
    }

    private func notifyFlutterError(code: String, message: String, details: String? = nil, recoverySuggestion: String? = nil) {
        
        DispatchQueue.main.async { [weak self] in
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

            guard let strongSelf = self else { return }
            strongSelf.dismiss(animated: true)

        }
    }

    // FIX 2: Add proper permission checking
    private func checkPermissions() async -> Bool {
        // Check camera permission
        let cameraStatus = AVCaptureDevice.authorizationStatus(for: .video)
        switch cameraStatus {
        case .denied, .restricted:
            handleError(.cameraPermissionDenied)
            return false
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            if !granted {
                handleError(.cameraPermissionDenied)
                return false
            }
        case .authorized:
            break
        @unknown default:
            handleError(.cameraPermissionUnknown)
            return false
        }
        
        // Check device capabilities
        guard RoomCaptureSession.isSupported else {
            handleError(.roomPlanNotSupported)
            return false
        }
        
        guard ARWorldTrackingConfiguration.isSupported else {
            handleError(.arKitNotSupported)
            return false
        }
        
        // Check storage space
        do {
            let availableStorage = try getAvailableStorage()
            if availableStorage < 100 * 1024 * 1024 { // 100MB
                handleError(.insufficientStorage)
                return false
            }
        } catch {
            handleError(.insufficientStorage)
            return false
        }
        
        // Check low power mode
        if ProcessInfo.processInfo.isLowPowerModeEnabled {
            handleError(.lowPowerMode)
            return false
        }
        
        return true
    }
    
    // Gets available storage space in bytes
    private func getAvailableStorage() throws -> Int64 {
        let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let values = try documentDirectory.resourceValues(forKeys: [.volumeAvailableCapacityKey])
        return Int64(values.volumeAvailableCapacity ?? 0)
    }

    // Classifies native errors into specific RoomPlanError types
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

        // Configure Cancel and Done Buttons
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.addTarget(self, action: #selector(cancelScanning), for: .touchUpInside)

        doneButton.setTitle("Done", for: .normal)
        doneButton.addTarget(self, action: #selector(doneScanning), for: .touchUpInside)

        activityIndicator.hidesWhenStopped = true

        // Add subviews
        [finishButton, cancelButton, doneButton, activityIndicator].forEach {
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

            finishButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            finishButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -30),
            finishButton.widthAnchor.constraint(equalToConstant: 120),
            finishButton.heightAnchor.constraint(equalToConstant: 44),

            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
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
        // FIX 3: Use async properly for startSession
        Task {
            await startSession()
        }
    }

    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopSession()
    }

    // FIX 4: Properly implement async startSession with permission checks
    private func startSession() async {
        // Check permissions before starting
        guard await checkPermissions() else {
            return
        }
        
        // Check if session is already running
        guard !isScanning else {
            handleError(.sessionInProgress)
            return
        }
        
        do {
            isScanning = true
            roomCaptureView.captureSession.run(configuration: roomCaptureSessionConfig)

            // Update UI on main thread
            await MainActor.run {
                // Hide Finish button
                finishButton.isHidden = true
                finishButton.alpha = 0.0

                // Show Done button again (in case it was hidden before)
                doneButton.isHidden = false
                doneButton.alpha = 1.0
            }
        } catch {
            isScanning = false
            let roomPlanError = classifyError(error)
            handleError(roomPlanError)
        }
    }

    private func stopSession() {
        guard isScanning else {
            return // Don't handle as error, just return silently
        }
        
        isScanning = false
        roomCaptureView.captureSession.stop()
        print("Scanning stopped")

        // Show Finish button
        finishButton.isHidden = false
        UIView.animate(withDuration: 0.3) {
            self.finishButton.alpha = 1.0
        }

        // Hide Done button
        UIView.animate(withDuration: 0.3) {
            self.doneButton.alpha = 0.0
        } completion: { _ in
            self.doneButton.isHidden = true
        }
    }

    // MARK: - RoomCaptureViewDelegate
    public func captureView(shouldPresent roomDataForProcessing: CapturedRoomData, error: Error?) -> Bool {
        if let error = error {
            print("Room capture failed with error: \(error)")
            let roomPlanError = classifyError(error)
            handleError(roomPlanError)
        }
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
        
        // FIX 5: Update UI on main thread
        DispatchQueue.main.async {
            self.finishButton.isEnabled = true
            self.activityIndicator.stopAnimating()
        }
    }

    // User Actions

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
        // FIX 6: Stop session before dismissing
        if isScanning {
            stopSession()
        }
        self.dismiss(animated: true)
    }

    private func exportToUSDZ() async -> Bool {
        guard let currentCapturedRoom = currentCapturedRoom else {
            print("No captured room data to export")
            return false
        }

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
    }

    @objc private func finishAndReturnResult() {
        guard let currentCapturedRoom = currentCapturedRoom else {
            notifyFlutterError(
                code: "no_data",
                message: "No captured room data available",
                details: "Current captured room is nil",
                recoverySuggestion: "Please complete a room scan before finishing"
            )
            self.dismiss(animated: true)
            return
        }

        // Show activity indicator while exporting
        activityIndicator.startAnimating()
        finishButton.isEnabled = false
        
        Task {
            do {
                // Export files and wait for completion
                let usdzSuccess = await exportToUSDZ()   
                
                await MainActor.run {
                    if usdzSuccess {
                        // Export succeeded, notify Flutter
                        if let controller = UIApplication.shared.delegate?.window??.rootViewController as? FlutterViewController {
                            let channel = FlutterMethodChannel(name: "rkg/flutter_roomplan", binaryMessenger: controller.binaryMessenger)
                            channel.invokeMethod("onRoomCaptureFinished", arguments: nil)
                        }
                        print("Export completed successfully")
                        self.activityIndicator.stopAnimating()
                        self.dismiss(animated: true)
                    } else {
                        // Export failed
                        print("Export failed - USDZ: \(usdzSuccess)")
                        self.notifyFlutterError(
                            code: "export_failed",
                            message: "Room export failed",
                            details: "USDZ Success: \(usdzSuccess)",
                            recoverySuggestion: "Try scanning again or check file permissions"
                        )
                        self.activityIndicator.stopAnimating()
                        self.dismiss(animated: true)
                    }
                }
            } catch {
                await MainActor.run {
                    self.notifyFlutterError(
                        code: "export_error",
                        message: "An error occurred during export",
                        details: error.localizedDescription,
                        recoverySuggestion: "Try scanning again"
                    )
                    self.activityIndicator.stopAnimating()
                    self.dismiss(animated: true)
                }
            }
        }
    }

    // FIX 7: Move deleteAllScanFiles inside the class and add proper error handling
    private func deleteAllScanFiles() {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let roomScansFolder = documentsPath.appendingPathComponent("RoomDataScans")
        
        do {
            if FileManager.default.fileExists(atPath: roomScansFolder.path) {
                try FileManager.default.removeItem(at: roomScansFolder)
                try FileManager.default.createDirectory(at: roomScansFolder, withIntermediateDirectories: true)
                
                print("Deleted all files in RoomDataScans folder")
            }
        } catch {
            print("Failed to delete scan files: \(error)")
            notifyFlutterError(
                code: "delete_failed",
                message: "Failed to delete scan files",
                details: error.localizedDescription,
                recoverySuggestion: "Try restarting the app or check storage permissions"
            )
        }
    }
}