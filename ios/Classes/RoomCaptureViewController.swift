import UIKit
import RoomPlan
import Flutter
import ARKit

@objc public class RoomCaptureViewController: UIViewController, RoomCaptureViewDelegate, RoomCaptureSessionDelegate {

    public var isMultiRoomModeEnabled: Bool = false
    private var isScanning = false
    private var roomCaptureView: RoomCaptureView!
    private var roomCaptureSessionConfig = RoomCaptureSession.Configuration()
    private var currentCapturedRoom: CapturedRoom?

    // load multiple capturedRoom results to capturedRoomArray
    var capturedRoomArray: [CapturedRoom] = []

    // Add ARWorldMap management for multi-room capture with persistent storage
    private var savedWorldMap: ARWorldMap?
    private let worldMapFileURL: URL = {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsPath.appendingPathComponent("RoomScanWorldMap.dat")
    }()
    
    public  var usdzFilePath: String?
    public  var jsonFilePath: String?

    private let finishButton = UIButton(type: .system)
    private let addMoreRooms = UIButton(type: .system)
    private let activityIndicator = UIActivityIndicatorView(style: .large)
    private let cancelButton = UIButton(type: .system)
    private let doneButton = UIButton(type: .system)

    public override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupRoomCaptureView()
        // activityIndicator.stopAnimating()
        // Clean up old files first
        cleanupOldScanFiles()
        
        // Load existing ARWorldMap if available
        loadSavedWorldMap()
    }

    @objc public static func isSupported() -> Bool {
        if #available(iOS 16.0, *) {
            return RoomCaptureSession.isSupported
        }
        return false
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

        // Configure Add More Rooms Button - Outlined style (only show on iOS 17.0+)
        addMoreRooms.setTitle("Add More Rooms", for: .normal)
        addMoreRooms.isEnabled = false
        addMoreRooms.isHidden = true
        addMoreRooms.alpha = 0.0
        addMoreRooms.backgroundColor = UIColor.clear
        addMoreRooms.setTitleColor(UIColor(red: 75/255.0, green: 58/255.0, blue: 47/255.0, alpha: 1.0), for: .normal)
        addMoreRooms.layer.cornerRadius = 12
        addMoreRooms.layer.borderWidth = 2.0
        addMoreRooms.layer.borderColor = UIColor(red: 75/255.0, green: 58/255.0, blue: 47/255.0, alpha: 1.0).cgColor
        addMoreRooms.addTarget(self, action: #selector(addMoreRoomsToMerge), for: .touchUpInside)

        // Configure Cancel and Done Buttons
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.addTarget(self, action: #selector(cancelScanning), for: .touchUpInside)

        doneButton.setTitle("Done", for: .normal)
        doneButton.addTarget(self, action: #selector(doneScanning), for: .touchUpInside)

        // Add subviews
        [finishButton, addMoreRooms, cancelButton, doneButton, activityIndicator].forEach {
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

                addMoreRooms.leadingAnchor.constraint(equalTo: view.centerXAnchor, constant: 10),
                addMoreRooms.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -40),
                addMoreRooms.widthAnchor.constraint(equalToConstant: 160),
                addMoreRooms.heightAnchor.constraint(equalToConstant: 44),
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

    // startSession with persistent ARWorldMap detection
    private func startSession() {
        isScanning = true
        
        //Configure session based on saved ARWorldMap availability
        if #available(iOS 17.0, *), isMultiRoomModeEnabled {
            if let worldMap = savedWorldMap {
                // ARWorldMap exists: Load it for additional room scanning
                print("Loading saved ARWorldMap for additional room scan")
                
                // First run AR relocalization with the world map
                 roomCaptureSessionConfig = RoomCaptureSession.Configuration()
                 let arSession = roomCaptureView.captureSession.arSession

                let arWorldTrackingConfig = ARWorldTrackingConfiguration()
                arWorldTrackingConfig.initialWorldMap = worldMap

                if roomCaptureView.captureSession.arSession.currentFrame != nil {
                roomCaptureView.captureSession.stop()
            }
                
                // Run ARKit relocalization with reset options for proper world alignment
                arSession.run(arWorldTrackingConfig, options: [.resetTracking, .removeExistingAnchors])
                
                // Wait briefly for relocalization, then start room capture
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    // Start room scan with configuration
                    self.roomCaptureView.captureSession.run(configuration: self.roomCaptureSessionConfig)
                    print("Room capture started with loaded ARWorldMap")
                }
            } else {
                // No ARWorldMap: Start fresh first room scan
                print("Starting fresh room scan - no saved ARWorldMap found")
                roomCaptureSessionConfig = RoomCaptureSession.Configuration()
                roomCaptureView.captureSession.run(configuration: roomCaptureSessionConfig)
            }
        } else {
            // Single room mode or iOS 16.0
            roomCaptureSessionConfig = RoomCaptureSession.Configuration()
            roomCaptureView.captureSession.run(configuration: roomCaptureSessionConfig)
        }
        
        // Hide Finish button
        finishButton.isHidden = true
        finishButton.alpha = 0.0

        // Hide add More Rooms button (only relevant for iOS 17.0+ with multi-room)
        if #available(iOS 17.0, *), isMultiRoomModeEnabled {
            addMoreRooms.isHidden = true
            addMoreRooms.alpha = 0.0
        }

        // Show Done button again (in case it was hidden before)
        doneButton.isHidden = false
        doneButton.alpha = 1.0
    }

    // stopSession to save ARWorldMap when needed
    private func stopSession() {
        isScanning = false
        
        //Save ARWorldMap for future multi-room sessions
        if #available(iOS 17.0, *), isMultiRoomModeEnabled {
            saveCurrentARWorldMap()
        }
        
        // Always fully stop session - each room is discrete
        if #available(iOS 17.0, *) {
            roomCaptureView.captureSession.stop(pauseARSession: false)
        } else {
            roomCaptureView.captureSession.stop()
        }

        // Show Finish button
        finishButton.isHidden = false
        UIView.animate(withDuration: 0.3) {
            self.finishButton.alpha = 1.0
        }

        // Show add More Rooms button only for iOS 17.0+ with multi-room enabled
        if #available(iOS 17.0, *), isMultiRoomModeEnabled {
            addMoreRooms.isHidden = false
            UIView.animate(withDuration: 0.3) {
                self.addMoreRooms.alpha = 1.0
            }
        }

        // Hide Done button
        UIView.animate(withDuration: 0.3) {
            self.doneButton.alpha = 0.0
        } completion: { _ in
            self.doneButton.isHidden = true
        }
    }

    // ARWorldMap persistent storage for multi-room continuity
    @available(iOS 17.0, *)
    private func saveCurrentARWorldMap() {
        guard isMultiRoomModeEnabled else { return }
        
        print("Saving ARWorldMap persistently for future room scans...")
        let arSession = roomCaptureView.captureSession.arSession
        arSession.getCurrentWorldMap { [weak self] worldMap, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Failed to save ARWorldMap: \(error.localizedDescription)")
                    self?.notifyFlutterError(code: "WORLDMAP_SAVE_FAILED", message: "Failed to save AR world map: \(error.localizedDescription)")
                } else if let worldMap = worldMap {
                    self?.savedWorldMap = worldMap
                    self?.saveWorldMapToDisk(worldMap)
                    print("Successfully saved ARWorldMap with \(worldMap.anchors.count) anchors")
                } else {
                    print("No ARWorldMap available to save")
                    self?.notifyFlutterError(code: "WORLDMAP_EMPTY", message: "No AR world map available for multi-room scanning")
                }
            }
        }
    }
    
    // Save ARWorldMap to persistent storage
    private func saveWorldMapToDisk(_ worldMap: ARWorldMap) {
        do {
            let data = try NSKeyedArchiver.archivedData(withRootObject: worldMap, requiringSecureCoding: true)
            try data.write(to: worldMapFileURL)
            print("ARWorldMap saved to disk at: \(worldMapFileURL.path)")
        } catch {
            print("Failed to save ARWorldMap to disk: \(error)")
            notifyFlutterError(code: "WORLDMAP_DISK_SAVE_FAILED", message: "Failed to save world map to disk: \(error.localizedDescription)")
        }
    }
    
    // Load ARWorldMap from persistent storage
    private func loadSavedWorldMap() {
        guard FileManager.default.fileExists(atPath: worldMapFileURL.path) else {
            print("No saved ARWorldMap found")
            return
        }
        
        do {
            let data = try Data(contentsOf: worldMapFileURL)
            if let worldMap = try NSKeyedUnarchiver.unarchivedObject(ofClass: ARWorldMap.self, from: data) {
                savedWorldMap = worldMap
                print("Successfully loaded ARWorldMap from disk with \(worldMap.anchors.count) anchors")
            }
        } catch {
            print("Failed to load ARWorldMap from disk: \(error)")
            // Clean up corrupted file
            try? FileManager.default.removeItem(at: worldMapFileURL)
        }
    }

    // Helper method to notify Flutter about errors
    private func notifyFlutterError(code: String, message: String) {
        if let controller = UIApplication.shared.delegate?.window??.rootViewController as? FlutterViewController {
            let channel = FlutterMethodChannel(name: "rkg/flutter_roomplan", binaryMessenger: controller.binaryMessenger)
            channel.invokeMethod("onErrorDetection", arguments: ["errorCode": code, "errorMessage": message])
        }
    }

    public func captureView(shouldPresent roomDataForProcessing: CapturedRoomData, error: Error?) -> Bool {
        return true
    }

    public func captureView(didPresent processedResult: CapturedRoom, error: Error?) {
        if let error = error {
            // Notify Flutter about room processing error
            notifyFlutterError(code: "ROOM_PROCESSING_FAILED", message: "Failed to process room data: \(error.localizedDescription)")
            return
        }
        
        currentCapturedRoom = processedResult
        capturedRoomArray.append(processedResult)
        finishButton.isEnabled = true
        
        // Update room tracking for multi-room mode
        if #available(iOS 17.0, *), isMultiRoomModeEnabled {
            print("Completed room scan - total rooms: \(capturedRoomArray.count)")
            addMoreRooms.isEnabled = true
        }
        
        // activityIndicator.stopAnimating()
    }

    @objc private func doneScanning() {
        stopSession()
        // activityIndicator.startAnimating()
    }

    @objc private func cancelScanning() {
        // Reset multi-room state on cancel
        if isScanning {
            if #available(iOS 17.0, *) {
                roomCaptureView.captureSession.stop(pauseARSession: false)
            } else {
                roomCaptureView.captureSession.stop()
            }
        }
        
        self.dismiss(animated: true)

        // Notify Flutter that user wants to scan another room
        if let controller = UIApplication.shared.delegate?.window??.rootViewController as? FlutterViewController {
            let channel = FlutterMethodChannel(name: "rkg/flutter_roomplan", binaryMessenger: controller.binaryMessenger)
            channel.invokeMethod("onScanCancelRequested", arguments: nil)
        }
    }


    private func resetMultiRoomState() async -> Bool {
    if #available(iOS 17.0, *), isMultiRoomModeEnabled {
        savedWorldMap = nil
        capturedRoomArray.removeAll()
        currentCapturedRoom = nil
        isScanning = false

        // Reset configuration to clear any saved world map
        roomCaptureSessionConfig = RoomCaptureSession.Configuration()

        do {
            if FileManager.default.fileExists(atPath: worldMapFileURL.path) {
                try FileManager.default.removeItem(at: worldMapFileURL)
                print("Multi-room state reset - ARWorldMap cleared from memory and disk")
            } else {
                print("No saved ARWorldMap found on disk")
            }
            return true
        } catch {
            print("Error deleting ARWorldMap file: \(error)")
            return false
        }
    }

    // If iOS version < 17 or multi-room mode disabled
    print("resetMultiRoomState skipped: Not supported or multi-room mode disabled")
    return false
   }


    private func exportToJSON() async -> Bool {
        guard let currentCapturedRoom = currentCapturedRoom else { 
            print("No captured room data to export")
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
            self.dismiss(animated: true)
            return
        }

        // Show activity indicator while exporting
        // activityIndicator.startAnimating()
        finishButton.isEnabled = false
        
        if #available(iOS 17.0, *), isMultiRoomModeEnabled {
            addMoreRooms.isEnabled = false
        }

        Task {
            do {
                // Export both files and wait for completion
                let usdzSuccess = await exportToUSDZ()
                let jsonSuccess = await exportToJSON()
                
                // Reset multi-room state after exporting
                let resetSuccess = await resetMultiRoomState()
                print("Reset multi-room state result: \(resetSuccess)")
                
                // Only call Flutter after both exports succeed
                await MainActor.run {
                    // self.activityIndicator.stopAnimating()
                    
                    if usdzSuccess && jsonSuccess {
                        // Both exports succeeded, notify Flutter
                        if let controller = UIApplication.shared.delegate?.window??.rootViewController as? FlutterViewController {
                            let channel = FlutterMethodChannel(name: "rkg/flutter_roomplan", binaryMessenger: controller.binaryMessenger)
                            channel.invokeMethod("onRoomCaptureFinished", arguments: nil)
                        }
                        print("Export completed successfully")
                       
                    } else {
                        // One or both exports failed
                        print("Export failed - USDZ: \(usdzSuccess), JSON: \(jsonSuccess)")
                        
                        // Notify Flutter about export failure
                        let errorCode = !usdzSuccess && !jsonSuccess ? "EXPORT_FAILED" : (!usdzSuccess ? "USDZ_EXPORT_FAILED" : "JSON_EXPORT_FAILED")
                        let errorMessage = !usdzSuccess && !jsonSuccess ? "Both USDZ and JSON export failed" : (!usdzSuccess ? "USDZ file export failed" : "JSON file export failed")
                        self.notifyFlutterError(code: errorCode, message: errorMessage)
                    }
                    
                    self.dismiss(animated: true)
                }
            } catch {
                await MainActor.run {
                    self.activityIndicator.stopAnimating()
                    finishButton.isEnabled = true
                    if #available(iOS 17.0, *), isMultiRoomModeEnabled {
                        addMoreRooms.isEnabled = true
                    }
                    print("Export failed: \(error)")
                    
                    // Notify Flutter about unexpected export error
                    self.notifyFlutterError(code: "EXPORT_EXCEPTION", message: "Unexpected error during export: \(error.localizedDescription)")
                    
                    self.dismiss(animated: true)
                }
            }
        }
    }

    // Dismiss and let user restart session for additional rooms
    @objc private func addMoreRoomsToMerge() {
        // This method should only be called on iOS 17.0+ with multi-room mode
        guard #available(iOS 17.0, *), isMultiRoomModeEnabled else {
            print("Multi-room mode not available")
            return
        }
        
        // Reset the current room scanning state
        currentCapturedRoom = nil
        
        // Hide the buttons and dismiss
        finishButton.isEnabled = false
        addMoreRooms.isEnabled = false
        
        UIView.animate(withDuration: 0.3) {
            self.finishButton.alpha = 0.0
            self.addMoreRooms.alpha = 0.0
        } completion: { _ in
            //Dismiss and let user restart - ARWorldMap will be detected automatically
            self.dismiss(animated: true)
            
            // Notify Flutter that user wants to add more rooms
            if let controller = UIApplication.shared.delegate?.window??.rootViewController as? FlutterViewController {
                let channel = FlutterMethodChannel(name: "rkg/flutter_roomplan", binaryMessenger: controller.binaryMessenger)
                channel.invokeMethod("onaddMoreRoomsRequested", arguments: ["totalRooms": self.capturedRoomArray.count, "hasPersistedWorldMap": true])
            }
        }
    }

    private func cleanupOldScanFiles(keepLastCount: Int = 10) {
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
        }
    }

    @objc public static func clearSavedArWorldMap() -> Bool {
        
    let worldMapFileURL: URL = {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsPath.appendingPathComponent("RoomScanWorldMap.dat")
    }()
    
    do {
        if FileManager.default.fileExists(atPath: worldMapFileURL.path) {
            try FileManager.default.removeItem(at: worldMapFileURL)
            print("Multi-room state reset - ARWorldMap cleared from memory and disk")
        } else {
            print("No saved ARWorldMap found on disk")
        }
        return true
    } catch {
        print("Error deleting ARWorldMap file: \(error)")
        return false
    }
   }
}