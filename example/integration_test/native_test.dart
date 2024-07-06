import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:nsfw_detector_flutter/nsfw_detector_flutter.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    print('Starting NSFW Detector tests...');
  });

  tearDownAll(() {
    print('NSFW Detector tests completed.');
  });

  if (Platform.isAndroid || Platform.isIOS) {
    test('NSFW Detection Test for nsfw', () async {
      final ByteData data = await rootBundle.load('assets/nsfw.jpeg');
      final Uint8List imageData = data.buffer.asUint8List();

      NsfwDetector detector = await NsfwDetector.load();
      NsfwResult? result = await detector.detectNSFWFromBytes(imageData);

      print("NSFW score: ${result?.score}");
      expect(result?.isNsfw, true);
    });

    test('NSFW Detection Test for bikini', () async {
      final ByteData data = await rootBundle.load('assets/bikini.jpeg');
      final Uint8List imageData = data.buffer.asUint8List();

      NsfwDetector detector = await NsfwDetector.load();
      NsfwResult? result = await detector.detectNSFWFromBytes(imageData);

      print("NSFW score: ${result?.score}");
      expect(result?.isNsfw, false);
    });

    test('NSFW Detection Test for dress', () async {
      final ByteData data = await rootBundle.load('assets/dress.jpeg');
      final Uint8List imageData = data.buffer.asUint8List();

      NsfwDetector detector = await NsfwDetector.load();
      NsfwResult? result = await detector.detectNSFWFromBytes(imageData);

      print("NSFW score: ${result?.score}");
      expect(result?.isNsfw, false);
    });
  } else {
    print('NSFW Detector tests skipped on non-Android and non-iOS platforms.');
  }
}
