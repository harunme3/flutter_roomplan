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
    setState(() {
      _isSupported = isSupported;
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
      await _flutterRoomplanPlugin.startScan(enableMultiRoom: true);
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
              ElevatedButton(
                onPressed: _isSupported ? _startRoomScan : null,
                child: const Text('Start Room Scan'),
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
