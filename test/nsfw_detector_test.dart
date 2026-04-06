import 'package:flutter_test/flutter_test.dart';
import 'package:nsfw_detector_flutter/src/nsfw_detector.dart';

void main() {
  group('NsfwResult', () {
    test('supports equality, hashCode, and toString', () {
      final first = NsfwResult(isNsfw: true, score: 0.87);
      final second = NsfwResult(isNsfw: true, score: 0.87);
      final different = NsfwResult(isNsfw: false, score: 0.87);

      expect(first, equals(second));
      expect(first.hashCode, equals(second.hashCode));
      expect(first, isNot(equals(different)));
      expect(first.toString(), 'NsfwResult(isNsfw: true, score: 0.87)');
    });
  });

  group('NsfwDetector.validateThreshold', () {
    test('rejects invalid threshold values', () {
      for (final threshold in <double>[
        double.nan,
        double.infinity,
        -0.1,
        1.1,
      ]) {
        expect(
          () => NsfwDetector.validateThreshold(threshold),
          throwsArgumentError,
        );
      }
    });

    test('accepts boundary threshold values', () {
      expect(() => NsfwDetector.validateThreshold(0.0), returnsNormally);
      expect(() => NsfwDetector.validateThreshold(1.0), returnsNormally);
    });
  });

  group('NsfwDetectorException', () {
    test('toString omits cause when one is not provided', () {
      expect(
        NsfwDetectorException('boom').toString(),
        'NsfwDetectorException: boom',
      );
    });

    test('toString includes the cause when one is provided', () {
      expect(
        NsfwDetectorException('boom', cause: 'root cause').toString(),
        'NsfwDetectorException: boom\nCause: root cause',
      );
    });
  });
}
