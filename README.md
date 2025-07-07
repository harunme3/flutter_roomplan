# 🏠 flutter_roomplan

**Seamlessly integrate Apple's RoomPlan SDK into your Flutter apps**  
Capture accurate 3D room scans using ARKit with this powerful plugin. Perfect for AR measurement, smart home, and interior design solutions.

---

## ⚠️ Requirements

- **iOS 16+**
- **ARKit-compatible device**:  
  iPhone 12 or later, or recent iPad Pro
- **LiDAR Scanner** required for accurate room scanning

---

## 📌 Key Features

- 📸 Launches native `RoomCaptureViewController` for full-screen AR scanning
- 🪄 Captures room geometry + objects as structured JSON
- 🔗 Simple Flutter API to start scans and handle results
- 🚀 Returns complete `CapturedRoom` JSON specification
- 📱 Device compatibility checking
- 📦 USDZ file export support

---

## 🚀 Quick Start

### 1️⃣ Installation

Add to `pubspec.yaml`:

```yaml
dependencies:
  flutter_roomplan: ^1.1.0
```

### 2️⃣ Basic Usage

```dart
import 'package:flutter_roomplan/flutter_roomplan.dart';

// Create plugin instance
final roomPlan = FlutterRoomplan();

// Check if device supports RoomPlan
final isSupported = await roomPlan.isSupported();

// Register callback for scan results
roomPlan.onRoomCaptureFinished((resultJson) {
  print('Room scan completed: $resultJson');
});

// Start room scanning
try {
  await roomPlan.startScan();
} catch (e) {
  print('Error starting scan: $e');
}

// Get USDZ file path after scan (if available)
final usdzPath = await roomPlan.getUsdzFilePath();
```

### 3️⃣ Available Methods

- `isSupported()`: Check if the device supports RoomPlan
- `startScan()`: Launch the room scanning interface
- `onRoomCaptureFinished()`: Register callback for scan results
- `getUsdzFilePath()`: Get path to exported USDZ file from last scan

### 4️⃣ Error Handling

The plugin throws exceptions for common errors:

- Device not supported
- Required permissions not granted
- Scan initialization failures

Always wrap `startScan()` in a try-catch block and check device support before scanning.

---

## 📝 Example

Check out the [example app](example/lib/main.dart) for a complete implementation showing:

- Device support checking
- Scan initiation
- Result handling
- USDZ file path retrieval
- Error management

---

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.
