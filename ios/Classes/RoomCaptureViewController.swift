import UIKit
import RoomPlan
import Flutter
import ARKit
import AVFoundation

@objc public class RoomCaptureViewController: UIViewController, RoomCaptureViewDelegate, RoomCaptureSessionDelegate {

    public var isMultiRoomModeEnabled: Bool = false
    private var isScanning = false
    private var roomCaptureView: RoomCaptureView!
    private var roomCaptureSessionConfig = RoomCaptureSession.Configuration()
    private var currentCapturedRoom: CapturedRoom?

    // load multiple capturedRoom results to capturedRoomArray
    var capturedRoomArray: [CapturedRoom] = []

    
    public var usdzFilePath: String?
    public var jsonFilePath: String?

    private let finishButton = UIButton(type: .system)
    private let scanOtherRoomsButton = UIButton(type: .system)
    private let activityIndicator = UIActivityIndicatorView(style: .large)
    private let cancelButton = UIButton(type: .system)
    private let doneButton = UIButton(type: .system)

    // Error handling properties
    private var sessionStartTime: Date?
    private let sessionTimeoutInterval: TimeInterval = 300 // 5 minutes

    public override func viewDidLoad() {
        super.viewDidLoad()
        
        // Check device compatibility first
        if !performDeviceCompatibilityCheck() {
            return // Error already handled in the method
        }
        
        resetScanningSession()
        setupUI()
        setupRoomCaptureView()
        activityIndicator.stopAnimating()
        // Clean up old files first
        cleanupOldScanFiles()
        
        // Monitor memory and thermal state
        startSystemMonitoring()
    }

    // MARK: - Device Compatibility & Permission Checks
    
    private func performDeviceCompatibilityCheck() -> Bool {
        // Check iOS version
        if #unavailable(iOS 16.0) {
            handleError(.unsupportedVersion)
            return false
        }
        
        // Check RoomPlan support
        guard RoomCaptureSession.isSupported else {
            handleError(.roomPlanNotSupported)
            return false
        }
        
        // Check ARKit support
        guard ARWorldTrackingConfiguration.isSupported else {
            handleError(.arKitNotSupported)
            return false
        }
        
        // Check hardware capabilities
        if !checkHardwareCapabilities() {
            handleError(.insufficientHardware)
            return false
        }
        
        // Check system state
        if !checkSystemState() {
            return false // Error already handled in checkSystemState
        }
        
        // Check camera permissions
        checkCameraPermissions()
        
        return true
    }
    
    private func checkHardwareCapabilities() -> Bool {
        let supportsSceneReconstruction = ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh)
        let deviceModel = getDeviceModel()
        
        // Check for LiDAR or advanced ARKit capabilities
        return supportsSceneReconstruction || RoomCaptureSession.isSupported
    }
    
    private func checkSystemState() -> Bool {
        // Check low power mode
        if ProcessInfo.processInfo.isLowPowerModeEnabled {
            handleError(.lowPowerMode)
            return false
        }
        
        // Check available storage
        if !hasEnoughStorage() {
            handleError(.insufficientStorage)
            return false
        }
        
        // Check thermal state
        let thermalState = ProcessInfo.processInfo.thermalState
        if thermalState == .critical || thermalState == .serious {
            handleError(.deviceOverheating)
            return false
        }
        
        // Check memory pressure
        if isMemoryPressureHigh() {
            handleError(.memoryPressure)
            return false
        }
        
        return true
    }
    
    private func checkCameraPermissions() {
        let cameraStatus = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch cameraStatus {
        case .denied:
            handleError(.cameraPermissionDenied)
        case .notDetermined:
            // Request permission
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    if !granted {
                        self?.handleError(.cameraPermissionDenied)
                    }
                }
            }
        case .restricted:
            handleError(.cameraPermissionUnknown)
        case .authorized:
            break // All good
        @unknown default:
            handleError(.cameraPermissionUnknown)
        }
    }
    
    // MARK: - System State Monitoring
    
    private func startSystemMonitoring() {
        // Monitor thermal state changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(thermalStateChanged),
            name: ProcessInfo.thermalStateDidChangeNotification,
            object: nil
        )
        
        // Monitor low power mode changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(lowPowerModeChanged),
            name: .NSProcessInfoPowerStateDidChange,
            object: nil
        )
        
        // Monitor app state changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        
        // Monitor memory warnings
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(memoryWarningReceived),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
    }
    
    @objc private func thermalStateChanged() {
        let thermalState = ProcessInfo.processInfo.thermalState
        if thermalState == .critical || thermalState == .serious {
            if isScanning {
                stopSession()
            }
            handleError(.deviceOverheating)
        }
    }
    
    @objc private func lowPowerModeChanged() {
        if ProcessInfo.processInfo.isLowPowerModeEnabled && isScanning {
            stopSession()
            handleError(.lowPowerMode)
        }
    }
    
    @objc private func appDidEnterBackground() {
        if isScanning {
            handleError(.backgroundModeActive)
        }
    }
    
    @objc private func memoryWarningReceived() {
        if isScanning {
            stopSession()
            handleError(.memoryPressure)
        }
    }
    
    // MARK: - Storage and Memory Utilities
    
    private func hasEnoughStorage(requiredMB: Int64 = 100) -> Bool {
        do {
            let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let values = try documentDirectory.resourceValues(forKeys: [.volumeAvailableCapacityKey])
            let availableBytes = values.volumeAvailableCapacity ?? 0
            let availableMB = Int64(availableBytes) / (1024 * 1024)
            return availableMB >= requiredMB
        } catch {
            return false
        }
    }
    
    private func isMemoryPressureHigh() -> Bool {
        // This is a simplified check - in a real app you might want more sophisticated memory monitoring
        let physicalMemory = ProcessInfo.processInfo.physicalMemory
        let usedMemory = mach_task_basic_info()
        return physicalMemory < 2 * 1024 * 1024 * 1024 // Less than 2GB total is considered low
    }

    @objc public static func isSupported() -> Bool {
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
    
    // Enhanced Flutter error notification
    private func notifyFlutterError(code: String, message: String, details: String? = nil, recoverySuggestion: String? = nil) {
        if let controller = UIApplication.shared.delegate?.window??.rootViewController as? FlutterViewController {
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

    // MARK: - UI Setup (keeping your existing UI setup)
    
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

    // MARK: - Session Management with Error Handling
    
    private func startSession() {
        // Check if another session is already running
        guard !isScanning else {
            handleError(.sessionInProgress)
            return
        }
        
        // Re-check system state before starting
        guard checkSystemState() else {
            return // Error already handled
        }
        
        // Check camera permissions again
        let cameraStatus = AVCaptureDevice.authorizationStatus(for: .video)
        guard cameraStatus == .authorized else {
            switch cameraStatus {
            case .denied:
                handleError(.cameraPermissionDenied)
            case .notDetermined:
                handleError(.cameraPermissionNotDetermined)
            default:
                handleError(.cameraPermissionUnknown)
            }
            return
        }

        do {
            isScanning = true
            sessionStartTime = Date()
            
            roomCaptureView.captureSession.run(configuration: roomCaptureSessionConfig)
            
            // Start session timeout timer
            startSessionTimeoutTimer()
            
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
            
        } catch {
            isScanning = false
            handleError(.worldTrackingFailed)
        }
    }
    
    private func startSessionTimeoutTimer() {
        DispatchQueue.main.asyncAfter(deadline: .now() + sessionTimeoutInterval) { [weak self] in
            guard let self = self, self.isScanning else { return }
            
            if let startTime = self.sessionStartTime,
               Date().timeIntervalSince(startTime) >= self.sessionTimeoutInterval {
                self.stopSession()
                self.handleError(.timeout("Room scanning session"))
            }
        }
    }

    private func stopSession() {
        guard isScanning else {
            handleError(.sessionNotRunning)
            return
        }
        
        isScanning = false
        sessionStartTime = nil
        
        do {
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
            
        } catch {
            // If stopping fails, still update the UI state
            isScanning = false
            print("Warning: Failed to stop session cleanly: \(error)")
        }
    }

    // MARK: - RoomCaptureSessionDelegate
    
    public func captureSession(_ session: RoomCaptureSession, didFailWithError error: Error) {
        print("RoomCaptureSession failed with error: \(error)")
        
        // Map various ARKit and RoomPlan errors to our custom errors
        if let arError = error as? ARError {
            switch arError.code {
            case .worldTrackingFailed:
                handleError(.worldTrackingFailed)
            case .insufficientFeatures:
                handleError(.worldTrackingFailed)
            case .cameraUnauthorized:
                handleError(.cameraPermissionDenied)
            default:
                handleError(.processingFailed(arError.localizedDescription))
            }
        } else {
            handleError(.processingFailed(error.localizedDescription))
        }
        
        // Stop the session on error
        if isScanning {
            stopSession()
        }
    }

    // ADDED: New method to handle scanning additional rooms in multi-room mode (iOS 17.0+ only)
    @objc private func scanOtherRooms() {
        // This method should only be called on iOS 17.0+ with multi-room mode
        guard #available(iOS 17.0, *), isMultiRoomModeEnabled else {
            return
        }
        
        // Check system state before starting new scan
        guard checkSystemState() else {
            return // Error already handled
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
        if let error = error {
            handleError(.dataCorrupted(error.localizedDescription))
            return false
        }
        return true
    }

    public func captureView(didPresent processedResult: CapturedRoom, error: Error?) {
        if let error = error {
            handleError(.processingFailed(error.localizedDescription))
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

    @objc private func doneScanning() {
        if isScanning {
            stopSession()
        } else {
            cancelScanning()
        }
        finishButton.isEnabled = false
        
        // Only disable scan other rooms button on iOS 17.0+ with multi-room mode
        if #available(iOS 17.0, *), isMultiRoomModeEnabled {
            scanOtherRoomsButton.isEnabled = false
        }
        
        activityIndicator.startAnimating()
    }

    @objc private func cancelScanning() {
        if isScanning {
            stopSession()
        }
        self.dismiss(animated: true)
    }

    // MARK: - Export Functions with Error Handling

    private func exportToJSON() async -> Bool {
        guard let currentCapturedRoom = currentCapturedRoom else { 
            print("No captured room data to export")
            handleError(.dataCorrupted("No room data available for export"))
            return false 
        }
        
        // Check storage before export
        if !hasEnoughStorage(requiredMB: 50) {
            handleError(.insufficientStorage)
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
            handleError(.exportFailed("JSON export failed: \(error.localizedDescription)"))
            return false
        }
    }

    private func exportToUSDZ() async -> Bool {
        guard let currentCapturedRoom = currentCapturedRoom else {
            print("No captured room data to export")
            handleError(.dataCorrupted("No room data available for export"))
            return false
        }
        
        // Check storage before export
        if !hasEnoughStorage(requiredMB: 100) {
            handleError(.insufficientStorage)
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
                handleError(.exportFailed("USDZ export failed: \(error.localizedDescription)"))
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
                handleError(.exportFailed("USDZ export failed: \(error.localizedDescription)"))
                return false
            }
        } else {
            print("USDZ export is only supported on iOS 16.0 or newer")
            handleError(.unsupportedVersion)
            return false
        }
    }

    @objc private func finishAndReturnResult() {
        guard let currentCapturedRoom = currentCapturedRoom else {
            handleError(.dataCorrupted("No room scan data available"))
            self.dismiss(animated: true)
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
                    } else {
                        // One or both exports failed - errors already handled in export methods
                        print("Export failed - USDZ: \(usdzSuccess), JSON: \(jsonSuccess)")
                    }
                    
                    self.dismiss(animated: true)
                }
            } catch {
                await MainActor.run {
                    self.activityIndicator.stopAnimating()
                    self.finishButton.isEnabled = true
                    if #available(iOS 17.0, *), self.isMultiRoomModeEnabled {
                        self.scanOtherRoomsButton.isEnabled = true
                    }
                    self.handleError(.exportFailed("Export process failed: \(error.localizedDescription)"))
                    self.dismiss(animated: true)
                }
            }
        }
    }

    // MARK: - Utility Functions (keeping your existing ones)

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
            // Don't throw an error to Flutter for cleanup failures - just log it
        }
    }

    private func resetScanningSession() {
        capturedRoomArray.removeAll()
        currentCapturedRoom = nil
        usdzFilePath = nil
        jsonFilePath = nil
        isScanning = false
        sessionStartTime = nil
    }
    
    // MARK: - Memory Management
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        
        if isScanning {
            stopSession()
        }
    }
}

// MARK: - Helper Functions (from your RoomPlanError file)

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