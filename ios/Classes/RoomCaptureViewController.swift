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

    
    public  var usdzFilePath: String?
    public  var jsonFilePath: String?

    private let finishButton = UIButton(type: .system)
    private let addMoreRooms = UIButton(type: .system)
    private let activityIndicator = UIActivityIndicatorView(style: .large)
    private let cancelButton = UIButton(type: .system)
    private let doneButton = UIButton(type: .system)
    
    // Global selection tracking
    private var selectedRoomTypes: [[String: String]] = []
    private var selectedDesignStyles: [[String: String]] = []
    
    // Current selection for the bottom sheet
    private var currentSelectedRoomType: [String: String]?
    private var currentSelectedDesignStyle: [String: String]?

    public override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupRoomCaptureView()
       // activityIndicator.stopAnimating()
        // Clean up old files first
        cleanupOldScanFiles()
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

    private func startSession() {

        isScanning = true
        roomCaptureView.captureSession.run(configuration: roomCaptureSessionConfig)
        
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


    public func captureView(shouldPresent roomDataForProcessing: CapturedRoomData, error: Error?) -> Bool {
        return true
    }

    public func captureView(didPresent processedResult: CapturedRoom, error: Error?) {
        if let error = error {
            // Notify Flutter about room processing error
            if let controller = UIApplication.shared.delegate?.window??.rootViewController as? FlutterViewController {
                let channel = FlutterMethodChannel(name: "rkg/flutter_roomplan", binaryMessenger: controller.binaryMessenger)
                channel.invokeMethod("onErrorDetection", arguments: ["errorCode": "ROOM_PROCESSING_FAILED", "errorMessage": "Failed to process room data: \(error.localizedDescription)"])
            }
            return
        }
        
        currentCapturedRoom = processedResult
        capturedRoomArray.append(processedResult)
        finishButton.isEnabled = true
        
        // Only enable add More Rooms button on iOS 17.0+ with multi-room mode
        if #available(iOS 17.0, *), isMultiRoomModeEnabled {
            addMoreRooms.isEnabled = true
        }
        
        // activityIndicator.stopAnimating()
        
    }

    @objc private func doneScanning() {
        stopSession()
        // activityIndicator.startAnimating()
    }

    @objc private func cancelScanning() {
          self.dismiss(animated: true)

        // Notify Flutter that user wants to scan another room
        if let controller = UIApplication.shared.delegate?.window??.rootViewController as? FlutterViewController {
            let channel = FlutterMethodChannel(name: "rkg/flutter_roomplan", binaryMessenger: controller.binaryMessenger)
            channel.invokeMethod("onScanCancelRequested", arguments: nil)
        }
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
                        if let controller = UIApplication.shared.delegate?.window??.rootViewController as? FlutterViewController {
                            let channel = FlutterMethodChannel(name: "rkg/flutter_roomplan", binaryMessenger: controller.binaryMessenger)
                            let errorCode = !usdzSuccess && !jsonSuccess ? "EXPORT_FAILED" : (!usdzSuccess ? "USDZ_EXPORT_FAILED" : "JSON_EXPORT_FAILED")
                            let errorMessage = !usdzSuccess && !jsonSuccess ? "Both USDZ and JSON export failed" : (!usdzSuccess ? "USDZ file export failed" : "JSON file export failed")
                            channel.invokeMethod("onErrorDetection", arguments: ["errorCode": errorCode, "errorMessage": errorMessage])
                        }
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
                if let controller = UIApplication.shared.delegate?.window??.rootViewController as? FlutterViewController {
                    let channel = FlutterMethodChannel(name: "rkg/flutter_roomplan", binaryMessenger: controller.binaryMessenger)
                    channel.invokeMethod("onErrorDetection", arguments: ["errorCode": "EXPORT_EXCEPTION", "errorMessage": "Unexpected error during export: \(error.localizedDescription)"])
                }
                
                self.dismiss(animated: true)
            }
        }
    }
  }

    // ADDED: New method to handle scanning additional rooms in multi-room mode (iOS 17.0+ only)
    @objc private func addMoreRoomsToMerge() {
        // This method should only be called on iOS 17.0+ with multi-room mode
        guard #available(iOS 17.0, *), isMultiRoomModeEnabled else {
            return
        }
        
        // Reset the current room scanning state
        currentCapturedRoom = nil
        
        // Hide the buttons and start a new scanning session
        finishButton.isEnabled = false
        addMoreRooms.isEnabled = false
        
        UIView.animate(withDuration: 0.3) {
            self.finishButton.alpha = 0.0
            self.addMoreRooms.alpha = 0.0
        } completion: { _ in
            self.finishButton.isHidden = true
            self.addMoreRooms.isHidden = true
            self.showBottomSheet()
            // Notify Flutter that user wants to scan another room
            if let controller = UIApplication.shared.delegate?.window??.rootViewController as? FlutterViewController {
                let channel = FlutterMethodChannel(name: "rkg/flutter_roomplan", binaryMessenger: controller.binaryMessenger)
                channel.invokeMethod("onaddMoreRoomsRequested", arguments: nil)
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
    
    // MARK: - Bottom Sheet Implementation
    private func showBottomSheet() {
        // Reset current selections for this session
        currentSelectedRoomType = nil
        currentSelectedDesignStyle = nil
        
        // Data for room types and design styles
        let roomTypes = [
            ["id": "1", "displayName": "Bedroom"],
            ["id": "2", "displayName": "Living Room"],
            ["id": "3", "displayName": "Kitchen"],
            ["id": "4", "displayName": "Studio"],
            ["id": "5", "displayName": "Office"]
        ]
        
        let designStyles = [
            ["id": "1", "displayName": "Modern"],
            ["id": "2", "displayName": "Minimalist"],
            ["id": "3", "displayName": "Contemporary"]
        ]
        
        // Create backdrop view
        let backdropView = UIView()
        backdropView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        backdropView.alpha = 0
        backdropView.translatesAutoresizingMaskIntoConstraints = false
        
        // Add tap gesture to dismiss
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissBottomSheet))
        backdropView.addGestureRecognizer(tapGesture)
        
        // Create bottom sheet container
        let bottomSheetContainer = UIView()
        bottomSheetContainer.backgroundColor = UIColor(red: 254/255.0, green: 246/255.0, blue: 242/255.0, alpha: 1.0)
        bottomSheetContainer.layer.cornerRadius = 20
        bottomSheetContainer.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        bottomSheetContainer.translatesAutoresizingMaskIntoConstraints = false
        
        // Create scroll view
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        
        // Create content view
        let contentView = UIView()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        // Title
        let titleLabel = UILabel()
        titleLabel.text = "Scanning and Floor Plan"
        titleLabel.font = UIFont(name: "Montserrat-Bold", size: 18) ?? UIFont.boldSystemFont(ofSize: 18)
        titleLabel.textColor = UIColor(red: 75/255.0, green: 58/255.0, blue: 47/255.0, alpha: 1.0)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Scan type section
        let scanTypeLabel = UILabel()
        scanTypeLabel.text = "What would you like to scan?"
        scanTypeLabel.font = UIFont(name: "Montserrat-Bold", size: 16) ?? UIFont.boldSystemFont(ofSize: 16)
        scanTypeLabel.textColor = UIColor(red: 75/255.0, green: 58/255.0, blue: 47/255.0, alpha: 1.0)
        scanTypeLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Single room option
        let singleRoomView = createScanOptionView(
            title: "A Single Room",
            subtitle: "Refresh your existing space with new layouts",
            isSelected: true
        )
        
        // Entire house option
        let entireHouseView = createScanOptionView(
            title: "My Entire House",
            subtitle: "Find furniture that fits your space",
            isSelected: false
        )
        
        // Room type section
        let roomTypeLabel = UILabel()
        roomTypeLabel.text = "What room are you designing?"
        roomTypeLabel.font = UIFont(name: "Montserrat-Bold", size: 16) ?? UIFont.boldSystemFont(ofSize: 16)
        roomTypeLabel.textColor = UIColor(red: 75/255.0, green: 58/255.0, blue: 47/255.0, alpha: 1.0)
        roomTypeLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let roomTypeSubtitle = UILabel()
        roomTypeSubtitle.text = "Let ARia help you with suggestions based on your needs"
        roomTypeSubtitle.font = UIFont(name: "Montserrat-Medium", size: 14.5) ?? UIFont.systemFont(ofSize: 14.5, weight: .medium)
        roomTypeSubtitle.textColor = UIColor(red: 69/255.0, green: 69/255.0, blue: 69/255.0, alpha: 1.0)
        roomTypeSubtitle.numberOfLines = 0
        roomTypeSubtitle.translatesAutoresizingMaskIntoConstraints = false
        
        // Room type grid
        let roomTypeStackView = createRoomTypeGrid(roomTypes: roomTypes)
        
        // Design style section
        let designStyleLabel = UILabel()
        designStyleLabel.text = "What is your preferred design style?"
        designStyleLabel.font = UIFont(name: "Montserrat-Bold", size: 16) ?? UIFont.boldSystemFont(ofSize: 16)
        designStyleLabel.textColor = UIColor(red: 75/255.0, green: 58/255.0, blue: 47/255.0, alpha: 1.0)
        designStyleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let designStyleSubtitle = UILabel()
        designStyleSubtitle.text = "Select a style that matches your taste"
        designStyleSubtitle.font = UIFont(name: "Montserrat-Medium", size: 14.5) ?? UIFont.systemFont(ofSize: 14.5, weight: .medium)
        designStyleSubtitle.textColor = UIColor(red: 69/255.0, green: 69/255.0, blue: 69/255.0, alpha: 1.0)
        designStyleSubtitle.translatesAutoresizingMaskIntoConstraints = false
        
        // Design style horizontal stack
        let designStyleStackView = createDesignStyleRow(designStyles: designStyles)
        
        // Continue button
        let continueButton = UIButton(type: .system)
        continueButton.setTitle("Continue", for: .normal)
        continueButton.titleLabel?.font = UIFont(name: "Montserrat-Medium", size: 16) ?? UIFont.systemFont(ofSize: 16, weight: .medium)
        continueButton.setTitleColor(.white, for: .normal)
        continueButton.backgroundColor = UIColor(red: 75/255.0, green: 58/255.0, blue: 47/255.0, alpha: 1.0)
        continueButton.layer.cornerRadius = 30
        continueButton.addTarget(self, action: #selector(continueButtonTapped), for: .touchUpInside)
        continueButton.translatesAutoresizingMaskIntoConstraints = false
        
        // Add all views to hierarchy
        view.addSubview(backdropView)
        view.addSubview(bottomSheetContainer)
        bottomSheetContainer.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        contentView.addSubview(titleLabel)
        contentView.addSubview(scanTypeLabel)
        contentView.addSubview(singleRoomView)
        contentView.addSubview(entireHouseView)
        contentView.addSubview(roomTypeLabel)
        contentView.addSubview(roomTypeSubtitle)
        contentView.addSubview(roomTypeStackView)
        contentView.addSubview(designStyleLabel)
        contentView.addSubview(designStyleSubtitle)
        contentView.addSubview(designStyleStackView)
        contentView.addSubview(continueButton)
        
        // Store references for dismissal
        backdropView.tag = 1001
        bottomSheetContainer.tag = 1002
        
        // Set up constraints
        NSLayoutConstraint.activate([
            // Backdrop
            backdropView.topAnchor.constraint(equalTo: view.topAnchor),
            backdropView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backdropView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backdropView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Bottom sheet container
            bottomSheetContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomSheetContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomSheetContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            bottomSheetContainer.heightAnchor.constraint(equalToConstant: 700),
            
            // Scroll view
            scrollView.topAnchor.constraint(equalTo: bottomSheetContainer.topAnchor, constant: 20),
            scrollView.leadingAnchor.constraint(equalTo: bottomSheetContainer.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: bottomSheetContainer.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomSheetContainer.bottomAnchor, constant: -20),
            
            // Content view
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            // Title
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            titleLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            
            // Scan type section
            scanTypeLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 30),
            scanTypeLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            
            singleRoomView.topAnchor.constraint(equalTo: scanTypeLabel.bottomAnchor, constant: 15),
            singleRoomView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            singleRoomView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            singleRoomView.heightAnchor.constraint(equalToConstant: 86),
            
            entireHouseView.topAnchor.constraint(equalTo: singleRoomView.bottomAnchor, constant: 8),
            entireHouseView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            entireHouseView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            entireHouseView.heightAnchor.constraint(equalToConstant: 86),
            
            // Room type section
            roomTypeLabel.topAnchor.constraint(equalTo: entireHouseView.bottomAnchor, constant: 25),
            roomTypeLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            
            roomTypeSubtitle.topAnchor.constraint(equalTo: roomTypeLabel.bottomAnchor, constant: 8),
            roomTypeSubtitle.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            roomTypeSubtitle.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            roomTypeStackView.topAnchor.constraint(equalTo: roomTypeSubtitle.bottomAnchor, constant: 20),
            roomTypeStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            roomTypeStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            // Design style section
            designStyleLabel.topAnchor.constraint(equalTo: roomTypeStackView.bottomAnchor, constant: 30),
            designStyleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            
            designStyleSubtitle.topAnchor.constraint(equalTo: designStyleLabel.bottomAnchor, constant: 8),
            designStyleSubtitle.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            
            designStyleStackView.topAnchor.constraint(equalTo: designStyleSubtitle.bottomAnchor, constant: 20),
            designStyleStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            designStyleStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            designStyleStackView.heightAnchor.constraint(equalToConstant: 88),
            
            // Continue button
            continueButton.topAnchor.constraint(equalTo: designStyleStackView.bottomAnchor, constant: 40),
            continueButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            continueButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            continueButton.heightAnchor.constraint(equalToConstant: 60),
            continueButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
        ])
        
        // Animate appearance
        bottomSheetContainer.transform = CGAffineTransform(translationX: 0, y: 700)
        
        UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseOut]) {
            backdropView.alpha = 1
            bottomSheetContainer.transform = .identity
        }
    }
    
    private func createScanOptionView(title: String, subtitle: String, isSelected: Bool) -> UIView {
        let containerView = UIView()
        containerView.backgroundColor = isSelected ? 
            UIColor(red: 255/255.0, green: 247/255.0, blue: 243/255.0, alpha: 1.0) :
            UIColor(red: 255/255.0, green: 242/255.0, blue: 235/255.0, alpha: 1.0)
        containerView.layer.cornerRadius = 20
        containerView.layer.borderWidth = isSelected ? 1.0 : 0.5
        containerView.layer.borderColor = isSelected ?
            UIColor(red: 75/255.0, green: 58/255.0, blue: 47/255.0, alpha: 1.0).cgColor :
            UIColor(red: 248/255.0, green: 225/255.0, blue: 212/255.0, alpha: 1.0).cgColor
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = UIFont(name: "Montserrat-SemiBold", size: 14.5) ?? UIFont.systemFont(ofSize: 14.5, weight: .semibold)
        titleLabel.textColor = UIColor(red: 33/255.0, green: 33/255.0, blue: 33/255.0, alpha: 1.0)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let subtitleLabel = UILabel()
        subtitleLabel.text = subtitle
        subtitleLabel.font = UIFont(name: "Montserrat-Medium", size: 12.5) ?? UIFont.systemFont(ofSize: 12.5, weight: .medium)
        subtitleLabel.textColor = UIColor(red: 69/255.0, green: 69/255.0, blue: 69/255.0, alpha: 1.0)
        subtitleLabel.numberOfLines = 0
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        containerView.addSubview(titleLabel)
        containerView.addSubview(subtitleLabel)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 15),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            subtitleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
        ])
        
        return containerView
    }
    
    private func createRoomTypeGrid(roomTypes: [[String: String]]) -> UIStackView {
        let mainStackView = UIStackView()
        mainStackView.axis = .vertical
        mainStackView.spacing = 8
        mainStackView.translatesAutoresizingMaskIntoConstraints = false
        
        // Create rows with 2 items each
        for i in stride(from: 0, to: roomTypes.count, by: 2) {
            let rowStackView = UIStackView()
            rowStackView.axis = .horizontal
            rowStackView.spacing = 8
            rowStackView.distribution = .fillEqually
            
            // First item in row
            let firstItem = createRoomTypeButton(roomType: roomTypes[i])
            rowStackView.addArrangedSubview(firstItem)
            
            // Second item in row (if exists)
            if i + 1 < roomTypes.count {
                let secondItem = createRoomTypeButton(roomType: roomTypes[i + 1])
                rowStackView.addArrangedSubview(secondItem)
            } else {
                // Add empty view to maintain layout
                let emptyView = UIView()
                rowStackView.addArrangedSubview(emptyView)
            }
            
            mainStackView.addArrangedSubview(rowStackView)
        }
        
        return mainStackView
    }
    
    private func createRoomTypeButton(roomType: [String: String]) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(roomType["displayName"], for: .normal)
        button.titleLabel?.font = UIFont(name: "Montserrat-SemiBold", size: 16) ?? UIFont.systemFont(ofSize: 16, weight: .semibold)
        button.tag = Int(roomType["id"] ?? "0") ?? 0
        
        // Check if this room type is already selected globally
        let isAlreadySelected = selectedRoomTypes.contains { selectedRoom in
            selectedRoom["id"] == roomType["id"]
        }
        
        if isAlreadySelected {
            // Disabled state - already selected
            button.isEnabled = false
            button.setTitleColor(UIColor.lightGray, for: .normal)
            button.backgroundColor = UIColor(red: 240/255.0, green: 240/255.0, blue: 240/255.0, alpha: 1.0)
            button.layer.borderWidth = 0.5
            button.layer.borderColor = UIColor.lightGray.cgColor
        } else {
            // Enabled state
            button.setTitleColor(UIColor(red: 33/255.0, green: 33/255.0, blue: 33/255.0, alpha: 1.0), for: .normal)
            button.backgroundColor = UIColor(red: 255/255.0, green: 247/255.0, blue: 243/255.0, alpha: 1.0)
            button.layer.borderWidth = 0.5
            button.layer.borderColor = UIColor(red: 235/255.0, green: 207/255.0, blue: 184/255.0, alpha: 1.0).cgColor
        }
        
        button.layer.cornerRadius = 10
        button.heightAnchor.constraint(equalToConstant: 102).isActive = true
        
        // Add target for selection
        button.addTarget(self, action: #selector(roomTypeButtonTapped(_:)), for: .touchUpInside)
        
        return button
    }
    
    private func createDesignStyleRow(designStyles: [[String: String]]) -> UIStackView {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 8
        stackView.distribution = .fillEqually
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        let colors = [
            UIColor(red: 164/255.0, green: 142/255.0, blue: 130/255.0, alpha: 1.0),
            UIColor(red: 115/255.0, green: 97/255.0, blue: 87/255.0, alpha: 1.0),
            UIColor(red: 75/255.0, green: 58/255.0, blue: 47/255.0, alpha: 1.0)
        ]
        
        for (index, style) in designStyles.enumerated() {
            let button = UIButton(type: .system)
            button.setTitle(style["displayName"], for: .normal)
            button.titleLabel?.font = UIFont(name: "Montserrat-Medium", size: 16) ?? UIFont.systemFont(ofSize: 16, weight: .medium)
            button.tag = Int(style["id"] ?? "0") ?? 0
            
            // Check if this design style is already selected globally
            let isAlreadySelected = selectedDesignStyles.contains { selectedStyle in
                selectedStyle["id"] == style["id"]
            }
            
            if isAlreadySelected {
                // Disabled state - already selected
                button.isEnabled = false
                button.setTitleColor(UIColor.lightGray, for: .normal)
                button.backgroundColor = UIColor(red: 200/255.0, green: 200/255.0, blue: 200/255.0, alpha: 1.0)
            } else {
                // Enabled state
                button.setTitleColor(.white, for: .normal)
                button.backgroundColor = colors[min(index, colors.count - 1)]
            }
            
            button.layer.cornerRadius = 10
            
            // Add target for selection
            button.addTarget(self, action: #selector(designStyleButtonTapped(_:)), for: .touchUpInside)
            
            stackView.addArrangedSubview(button)
        }
        
        return stackView
    }
    
    @objc private func dismissBottomSheet() {
        guard let backdropView = view.viewWithTag(1001),
              let bottomSheetContainer = view.viewWithTag(1002) else { return }
        
        UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseIn]) {
            backdropView.alpha = 0
            bottomSheetContainer.transform = CGAffineTransform(translationX: 0, y: 700)
        } completion: { _ in
            backdropView.removeFromSuperview()
            bottomSheetContainer.removeFromSuperview()
        }
    }
    
    @objc private func continueButtonTapped() {
        // Validate selections before continuing
        guard let roomType = currentSelectedRoomType,
              let designStyle = currentSelectedDesignStyle else {
            showToast(message: "Please select both a room type and design style to continue")
            return
        }
        
        // Add selections to global arrays
        selectedRoomTypes.append(roomType)
        selectedDesignStyles.append(designStyle)
        
        print("Selected Room Type: \(roomType["displayName"] ?? "Unknown"), Design Style: \(designStyle["displayName"] ?? "Unknown")")
        
        dismissBottomSheet()
        // Call startSession after dismissing the bottom sheet
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.startSession()
        }
    }
    
    @objc private func roomTypeButtonTapped(_ sender: UIButton) {
        guard let roomTypes = [
            ["id": "1", "displayName": "Bedroom"],
            ["id": "2", "displayName": "Living Room"],
            ["id": "3", "displayName": "Kitchen"],
            ["id": "4", "displayName": "Studio"],
            ["id": "5", "displayName": "Office"]
        ].first(where: { Int($0["id"] ?? "0") == sender.tag }) else { return }
        
        // Update current selection
        currentSelectedRoomType = roomTypes
        
        // Update UI to show selection
        updateRoomTypeButtonSelection(selectedTag: sender.tag)
        
        print("Room type selected: \(roomTypes["displayName"] ?? "Unknown")")
    }
    
    @objc private func designStyleButtonTapped(_ sender: UIButton) {
        guard let designStyles = [
            ["id": "1", "displayName": "Modern"],
            ["id": "2", "displayName": "Minimalist"],
            ["id": "3", "displayName": "Contemporary"]
        ].first(where: { Int($0["id"] ?? "0") == sender.tag }) else { return }
        
        // Update current selection
        currentSelectedDesignStyle = designStyles
        
        // Update UI to show selection
        updateDesignStyleButtonSelection(selectedTag: sender.tag)
        
        print("Design style selected: \(designStyles["displayName"] ?? "Unknown")")
    }
    
    private func updateRoomTypeButtonSelection(selectedTag: Int) {
        // Find all room type buttons and update their appearance
        guard let bottomSheetContainer = view.viewWithTag(1002) else { return }
        
        func findRoomTypeButtons(in view: UIView) -> [UIButton] {
            var buttons: [UIButton] = []
            for subview in view.subviews {
                if let button = subview as? UIButton, 
                   button.tag >= 1 && button.tag <= 5 && 
                   button.titleLabel?.font?.fontName.contains("Montserrat-SemiBold") == true {
                    buttons.append(button)
                } else {
                    buttons.append(contentsOf: findRoomTypeButtons(in: subview))
                }
            }
            return buttons
        }
        
        let roomTypeButtons = findRoomTypeButtons(in: bottomSheetContainer)
        
        for button in roomTypeButtons {
            if button.tag == selectedTag {
                // Selected state
                button.backgroundColor = UIColor(red: 75/255.0, green: 58/255.0, blue: 47/255.0, alpha: 0.2)
                button.layer.borderWidth = 2.0
                button.layer.borderColor = UIColor(red: 75/255.0, green: 58/255.0, blue: 47/255.0, alpha: 1.0).cgColor
            } else if button.isEnabled {
                // Unselected but enabled state
                button.backgroundColor = UIColor(red: 255/255.0, green: 247/255.0, blue: 243/255.0, alpha: 1.0)
                button.layer.borderWidth = 0.5
                button.layer.borderColor = UIColor(red: 235/255.0, green: 207/255.0, blue: 184/255.0, alpha: 1.0).cgColor
            }
        }
    }
    
    private func updateDesignStyleButtonSelection(selectedTag: Int) {
        // Find all design style buttons and update their appearance
        guard let bottomSheetContainer = view.viewWithTag(1002) else { return }
        
        let colors = [
            UIColor(red: 164/255.0, green: 142/255.0, blue: 130/255.0, alpha: 1.0),
            UIColor(red: 115/255.0, green: 97/255.0, blue: 87/255.0, alpha: 1.0),
            UIColor(red: 75/255.0, green: 58/255.0, blue: 47/255.0, alpha: 1.0)
        ]
        
        func findDesignStyleButtons(in view: UIView) -> [UIButton] {
            var buttons: [UIButton] = []
            for subview in view.subviews {
                if let button = subview as? UIButton,
                   button.tag >= 1 && button.tag <= 3 && 
                   button.titleLabel?.font?.fontName.contains("Montserrat-Medium") == true {
                    buttons.append(button)
                } else {
                    buttons.append(contentsOf: findDesignStyleButtons(in: subview))
                }
            }
            return buttons
        }
        
        let designStyleButtons = findDesignStyleButtons(in: bottomSheetContainer)
        
        for button in designStyleButtons {
            if button.tag == selectedTag {
                // Selected state - add border
                button.layer.borderWidth = 3.0
                button.layer.borderColor = UIColor.white.cgColor
            } else if button.isEnabled {
                // Unselected but enabled state
                button.layer.borderWidth = 0.0
                button.backgroundColor = colors[min(button.tag - 1, colors.count - 1)]
            }
        }
    }
    
    private func showToast(message: String) {
        // Remove any existing toast
        view.subviews.filter { $0.tag == 9999 }.forEach { $0.removeFromSuperview() }
        
        // Create toast container
        let toastContainer = UIView()
        toastContainer.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        toastContainer.layer.cornerRadius = 25
        toastContainer.tag = 9999
        toastContainer.translatesAutoresizingMaskIntoConstraints = false
        
        // Create toast label
        let toastLabel = UILabel()
        toastLabel.text = message
        toastLabel.textColor = .white
        toastLabel.font = UIFont(name: "Montserrat-Medium", size: 14) ?? UIFont.systemFont(ofSize: 14, weight: .medium)
        toastLabel.textAlignment = .center
        toastLabel.numberOfLines = 0
        toastLabel.translatesAutoresizingMaskIntoConstraints = false
        
        toastContainer.addSubview(toastLabel)
        view.addSubview(toastContainer)
        
        // Set up constraints
        NSLayoutConstraint.activate([
            toastContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            toastContainer.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            toastContainer.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 20),
            toastContainer.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -20),
            
            toastLabel.topAnchor.constraint(equalTo: toastContainer.topAnchor, constant: 12),
            toastLabel.bottomAnchor.constraint(equalTo: toastContainer.bottomAnchor, constant: -12),
            toastLabel.leadingAnchor.constraint(equalTo: toastContainer.leadingAnchor, constant: 20),
            toastLabel.trailingAnchor.constraint(equalTo: toastContainer.trailingAnchor, constant: -20)
        ])
        
        // Animate appearance and auto-dismiss
        toastContainer.alpha = 0
        toastContainer.transform = CGAffineTransform(translationX: 0, y: -20)
        
        UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseOut]) {
            toastContainer.alpha = 1
            toastContainer.transform = .identity
        }
        
        // Auto dismiss after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseIn]) {
                toastContainer.alpha = 0
                toastContainer.transform = CGAffineTransform(translationX: 0, y: -20)
            } completion: { _ in
                toastContainer.removeFromSuperview()
            }
        }
    }

}
