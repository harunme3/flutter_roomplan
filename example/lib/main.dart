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
  bool isMultiRoomSupported = false;
  String? usdzFilePath;
  String? jsonFilePath;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkSupport();
    });

    flutterRoomplan.onaddMoreRoomsRequested(() async {
      debugPrint('Scan other rooms requested');
      //add new entries in list for room when scan other rooms is requested
    });

    flutterRoomplan.onScanCancelRequested(() async {
      debugPrint('Scan cancel requested');
      //cancel the scan
    });

    flutterRoomplan.onRoomCaptureFinished(() async {
      debugPrint('Room scan completed');
      // Get the USDZ and JSON file paths after scan is complete
      final usdzPath = await flutterRoomplan.getUsdzFilePath();
      final jsonPath = await flutterRoomplan.getJsonFilePath();
      setState(() {
        usdzFilePath = usdzPath;
        jsonFilePath = jsonPath;
      });
    });
  }

  Future<void> _checkSupport() async {
    final isSupported = await flutterRoomplan.isSupported();
    final isMultiRoomSupported = await flutterRoomplan.isMultiRoomSupported();
    setState(() {
      this.isSupported = isSupported;
      this.isMultiRoomSupported = isMultiRoomSupported;
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
              if (isMultiRoomSupported)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        'Multi-Room: Supported ✅ (iOS 17.0+)',
                        style: TextStyle(color: Colors.green),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () {
                          flutterRoomplan.startScan(enableMultiRoom: true);
                        },
                        child: Text('Start Multi-Room Scan'),
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
              if (jsonFilePath != null)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Scanned JSON file:\n$jsonFilePath',
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
