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
  final _flutterRoomplanPlugin = FlutterRoomplan();
  bool _isSupported = false;
  bool _isMultiRoomSupported = false;
  String? _lastUsdzFilePath;
  String? _lastJsonFilePath;

  @override
  void initState() {
    super.initState();
    _checkSupport();
    _flutterRoomplanPlugin.onRoomCaptureFinished(() async {
      debugPrint('Room scan completed');

      /// Get the USDZ and JSON file paths after scan is complete
      final usdzPath = await _flutterRoomplanPlugin.getUsdzFilePath();
      final jsonPath = await _flutterRoomplanPlugin.getJsonFilePath();
      setState(() {
        _lastUsdzFilePath = usdzPath;
        _lastJsonFilePath = jsonPath;
      });
    });
  }

  Future<void> _checkSupport() async {
    final isSupported = await _flutterRoomplanPlugin.isSupported();
    final isMultiRoomSupported = await _flutterRoomplanPlugin.isMultiRoomSupported();
    setState(() {
      _isSupported = isSupported;
      _isMultiRoomSupported = isMultiRoomSupported;
    });
  }

  Future<void> _startRoomScan() async {
    if (!_isSupported) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('RoomPlan is not supported on this device'),
          ),
        );
      }
      return;
    }

    try {
      await _flutterRoomplanPlugin.startScan(enableMultiRoom: _isMultiRoomSupported);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('RoomPlan Example')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!_isSupported)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'RoomPlan is not supported on this device',
                    style: TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
              if (_isSupported)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        'RoomPlan: Supported ✅',
                        style: TextStyle(color: Colors.green),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isMultiRoomSupported
                            ? 'Multi-Room: Supported ✅ (iOS 17.0+)'
                            : 'Multi-Room: Not Supported ❌ (Requires iOS 17.0+)',
                        style: TextStyle(
                          color: _isMultiRoomSupported ? Colors.green : Colors.orange,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ElevatedButton(
                onPressed: _isSupported ? _startRoomScan : null,
                child: Text(
                  _isMultiRoomSupported
                      ? 'Start Multi-Room Scan'
                      : 'Start Single Room Scan',
                ),
              ),
              if (_lastUsdzFilePath != null)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Last scan USDZ file:\n$_lastUsdzFilePath',
                    textAlign: TextAlign.center,
                  ),
                ),
              if (_lastJsonFilePath != null)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Last scan JSON file:\n$_lastJsonFilePath',
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
