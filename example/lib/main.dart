import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_roomplan/flutter_roomplan.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final FlutterRoomplan flutterRoomplan = FlutterRoomplan();
  bool isSupported = false;
  String? usdzFilePath;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkSupport();
    });
    flutterRoomplan.onRoomCaptureFinished(() async {
      debugPrint('Room scan completed');
      // Get the USDZ and JSON file paths after scan is complete
      final usdzPath = await flutterRoomplan.getUsdzFilePath();
      setState(() {
        usdzFilePath = usdzPath;
      });
    });
    flutterRoomplan.onErrorDetection((
      String? code,
      String? message,
      String? details,
      String? recoverySuggestion,
    ) {
      debugPrint(
        'Error detected: code=$code, message=$message, details=$details, recoverySuggestion=$recoverySuggestion',
      );
    });
  }

  Future<void> _checkSupport() async {
    final isSupported = await flutterRoomplan.isSupported();

    setState(() {
      this.isSupported = isSupported;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('RoomPlan Example')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (isSupported)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        'RoomPlan: Supported ✅ (iOS 16.0+)',
                        style: TextStyle(color: Colors.green),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () {
                          flutterRoomplan.startScan();
                        },
                        child: Text('Start Room Scan'),
                      ),
                    ],
                  ),
                ),
              if (usdzFilePath != null)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Scanned USDZ file:\n$usdzFilePath',
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
