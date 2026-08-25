// ignore_for_file: avoid_print

import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:nsfw_detector_flutter/nsfw_detector_flutter.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late NsfwDetector detector;

  setUpAll(() async {
    print('Starting NSFW Detector tests...');
    detector = await NsfwDetector.load();
  });

  tearDownAll(() {
    print('NSFW Detector tests completed.');
    detector.close();
  });

  if (Platform.isAndroid || Platform.isIOS) {
    test('NSFW Detection Test for nsfw', () async {
      final ByteData data = await rootBundle.load('assets/nsfw.jpeg');
      final Uint8List imageData = data.buffer.asUint8List();

      NsfwResult? result = await detector.detectNSFWFromBytes(imageData);

      print("NSFW score: ${result?.score}");
      expect(result?.isNsfw, true);
    });

    test('NSFW Detection Test in background isolate', () async {
      final ByteData data = await rootBundle.load('assets/nsfw.jpeg');
      final Uint8List imageData = data.buffer.asUint8List();

      final first = await NsfwDetector.detectBytesInBackground(imageData);
      final second = await NsfwDetector.detectBytesInBackground(imageData);

      print('Background NSFW score: ${first?.score}');
      expect(first?.isNsfw, true);
      expect(second?.isNsfw, true);
    });

    test('Background detection rejects empty bytes', () async {
      await expectLater(
        NsfwDetector.detectBytesInBackground(Uint8List(0)),
        throwsArgumentError,
      );
    });

    test('NSFW Detection Test for bikini', () async {
      final ByteData data = await rootBundle.load('assets/bikini.jpeg');
      final Uint8List imageData = data.buffer.asUint8List();

      NsfwResult? result = await detector.detectNSFWFromBytes(imageData);

      print("NSFW score: ${result?.score}");
      expect(result?.isNsfw, false);
    });

    test('NSFW Detection Test for dress', () async {
      final ByteData data = await rootBundle.load('assets/dress.jpeg');
      final Uint8List imageData = data.buffer.asUint8List();

      NsfwResult? result = await detector.detectNSFWFromBytes(imageData);

      print("NSFW score: ${result?.score}");
      expect(result?.isNsfw, false);
    });

    test('URL detection enforces the response size limit', () async {
      final data = await rootBundle.load('assets/nsfw.jpeg');
      final imageData = data.buffer.asUint8List();
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.listen((request) {
        request.response.contentLength = imageData.length;
        request.response.add(imageData);
        request.response.close();
      });

      try {
        await expectLater(
          detector.detectNSFWFromUrl(
            Uri.parse('http://${server.address.host}:${server.port}/image'),
            maxBytes: imageData.length - 1,
          ),
          throwsA(isA<NsfwDetectorException>()),
        );
      } finally {
        await server.close(force: true);
      }
    });

    test('Singleton initialization is safe when called concurrently', () async {
      NsfwDetector.disposeInstance();

      await Future.wait([
        NsfwDetector.initialize(),
        NsfwDetector.initialize(),
      ]);

      expect(NsfwDetector.isInitialized, isTrue);
      NsfwDetector.disposeInstance();
    });

    test('Detector close is idempotent', () async {
      final disposable = await NsfwDetector.load();

      disposable.close();
      disposable.close();
    });
  } else {
    print('NSFW Detector tests skipped on non-Android and non-iOS platforms.');
  }
}
