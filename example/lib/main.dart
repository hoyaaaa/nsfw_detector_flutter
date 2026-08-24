import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:nsfw_detector_flutter/nsfw_detector_flutter.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _result = "Loading...";

  @override
  void initState() {
    super.initState();
    _detectNSFW();
  }

  Future<void> _detectNSFW() async {
    try {
      // Load the image file
      final ByteData data = await rootBundle.load('assets/nsfw.jpeg');
      final Uint8List imageData = data.buffer.asUint8List();

      // Load and initialize the NSFW detector
      final detector = await NsfwDetector.load();
      try {
        final result = await detector.detectNSFWFromBytes(imageData);

        if (!mounted) return;
        setState(() {
          _result = 'NSFW score: ${result?.score}, Detected: ${result?.isNsfw}';
        });
      } finally {
        detector.close();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _result = 'Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('NSFW Detector Example'),
        ),
        body: Center(
          child: Text(_result),
        ),
      ),
    );
  }
}
