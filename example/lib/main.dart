import 'package:flutter/material.dart';
import 'package:nsfw_detector_flutter/nsfw_detector_flutter.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _result = "Loading...";

  @override
  void initState() {
    super.initState();
    _detectNSFW();
  }

  Future<void> _detectNSFW() async {
    // Load the image file
    final ByteData data = await rootBundle.load('assets/nsfw.jpeg');
    final Uint8List imageData = data.buffer.asUint8List();
    img.Image image = img.decodeImage(imageData)!;

    // Load and initialize the NSFW detector
    NsfwDetector detector = await NsfwDetector.load();
    NsfwResult? result = await detector.detectNSFWFromImage(image);

    setState(() {
      _result = 'NSFW score: ${result?.score}, Detected: ${result?.isNsfw}';
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('NSFW Detector Example'),
        ),
        body: Center(
          child: Text(_result),
        ),
      ),
    );
  }
}
