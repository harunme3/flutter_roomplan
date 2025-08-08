import UIKit
import RoomPlan
import Flutter
import ARKit

@objc public class RoomCaptureViewController: UIViewController, RoomCaptureViewDelegate, RoomCaptureSessionDelegate {

    public var enableMultiRoomMode: Bool = false
    private var isScanning = false
    private var roomCaptureView: RoomCaptureView!
    private var roomCaptureSessionConfig = RoomCaptureSession.Configuration()
    private var finalResults: CapturedRoom?

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
        setupUI()
        setupRoomCaptureView()
        activityIndicator.stopAnimating()
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
        if #available(iOS 17.0, *), enableMultiRoomMode {
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
        if #available(iOS 17.0, *), enableMultiRoomMode {
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
            roomCaptureView.captureSession.stop(pauseARSession: !enableMultiRoomMode)
        } else {
            roomCaptureView.captureSession.stop()
        }

        // Show Finish button
        finishButton.isHidden = false
        UIView.animate(withDuration: 0.3) {
            self.finishButton.alpha = 1.0
        }

        // Show scan other rooms button only for iOS 17.0+ with multi-room enabled
        if #available(iOS 17.0, *), enableMultiRoomMode {
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

    public func captureView(shouldPresent roomDataForProcessing: CapturedRoomData, error: Error?) -> Bool {
        return true
    }

    private func exportToJSON() {
        guard let finalResults = finalResults else { return }
        

        do {
            let jsonEncoder = JSONEncoder()
            jsonEncoder.outputFormatting = [.prettyPrinted]
            
            // For iOS 16.0, export single room; for iOS 17.0+ with multi-room, export array
            let dataToExport: Data
            if #available(iOS 17.0, *), enableMultiRoomMode {
                dataToExport = try jsonEncoder.encode(capturedRoomArray)
            } else {
                dataToExport = try jsonEncoder.encode(finalResults)
            }
            
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let roomScansFolder = documentsPath.appendingPathComponent("RoomScans")
            
            // Create the RoomScans directory if it doesn't exist
            if !FileManager.default.fileExists(atPath: roomScansFolder.path) {
                try FileManager.default.createDirectory(at: roomScansFolder, withIntermediateDirectories: true)
            }
            
            let fileName = "room_scan_\(Int(Date().timeIntervalSince1970)).json"
            let fileURL = roomScansFolder.appendingPathComponent(fileName)
            
            try dataToExport.write(to: fileURL)
            self.jsonFilePath = fileURL.path
            
            print("Successfully exported JSON file to: \(fileURL.path)")
            
        } catch {
            print("Failed to export JSON file: \(error)")
        }
    }

    private func exportToUSDZ() {
        guard let finalResults = finalResults else { return }


        if #available(iOS 17.0, *) {
            Task {
                do {
                    let structureBuilder = StructureBuilder(options: [.beautifyObjects])
                    let capturedStructure: CapturedStructure
                    
                    // Use merge API for multi-room in iOS 17.0+, single room for others
                    if enableMultiRoomMode {
                        capturedStructure = try await structureBuilder.capturedStructure(from: capturedRoomArray)
                    } else {
                        capturedStructure = try await structureBuilder.capturedStructure(from: [finalResults])
                    }

                    let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                    let roomScansFolder = documentsPath.appendingPathComponent("RoomScans")

                    if !FileManager.default.fileExists(atPath: roomScansFolder.path) {
                        try FileManager.default.createDirectory(at: roomScansFolder, withIntermediateDirectories: true)
                    }

                    let fileName = "room_scan_\(Int(Date().timeIntervalSince1970)).usdz"
                    let fileURL = roomScansFolder.appendingPathComponent(fileName)

                    try capturedStructure.export(to: fileURL)
                    self.usdzFilePath = fileURL.path
                } catch {
                    print("Failed to export USDZ file: \(error)")
                }
            }
        } else if #available(iOS 16.0, *) {
            // For iOS 16.0, use the single room export method
            Task {
                do {
               
                    let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                    let roomScansFolder = documentsPath.appendingPathComponent("RoomScans")

                    if !FileManager.default.fileExists(atPath: roomScansFolder.path) {
                        try FileManager.default.createDirectory(at: roomScansFolder, withIntermediateDirectories: true)
                    }

                    let fileName = "room_scan_\(Int(Date().timeIntervalSince1970)).usdz"
                    let fileURL = roomScansFolder.appendingPathComponent(fileName)

                    try finalResults.export(to: fileURL)
                    self.usdzFilePath = fileURL.path
                } catch {
                    print("Failed to export USDZ file: \(error)")
                }
            }
        } else {
            print("USDZ export is only supported on iOS 16.0 or newer")
        }
    }

    public func captureView(didPresent processedResult: CapturedRoom, error: Error?) {
        finalResults = processedResult
        capturedRoomArray.append(processedResult)
        finishButton.isEnabled = true
        
        // Only enable scan other rooms button on iOS 17.0+ with multi-room mode
        if #available(iOS 17.0, *), enableMultiRoomMode {
            scanOtherRoomsButton.isEnabled = true
        }
        
        activityIndicator.stopAnimating()
        
        // Export files
        exportToUSDZ()
        exportToJSON()
    }

    @objc private func doneScanning() {
        if isScanning {
            stopSession()
        } else {
            cancelScanning()
        }
        finishButton.isEnabled = false
        
        // Only disable scan other rooms button on iOS 17.0+ with multi-room mode
        if #available(iOS 17.0, *), enableMultiRoomMode {
            scanOtherRoomsButton.isEnabled = false
        }
        
        activityIndicator.startAnimating()
    }

    @objc private func cancelScanning() {
        self.dismiss(animated: true)
    }

    @objc private func finishAndReturnResult() {
        guard let finalResults = finalResults else {
            self.dismiss(animated: true)
            return
        }

        do {
           // Send notification to Flutter via MethodChannel
            if let controller = UIApplication.shared.delegate?.window??.rootViewController as? FlutterViewController {
                let channel = FlutterMethodChannel(name: "rkg/flutter_roomplan", binaryMessenger: controller.binaryMessenger)
                channel.invokeMethod("onRoomCaptureFinished", arguments: nil)
            }
        } catch {
            print("Failed to encode finalResults: \(error)")
        }

        self.dismiss(animated: true)
    }

    // ADDED: New method to handle scanning additional rooms in multi-room mode (iOS 17.0+ only)
    @objc private func scanOtherRooms() {
        // This method should only be called on iOS 17.0+ with multi-room mode
        guard #available(iOS 17.0, *), enableMultiRoomMode else {
            return
        }
        
        // Reset the current room scanning state
        finalResults = nil
        
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
}