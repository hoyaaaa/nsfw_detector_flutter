import 'package:flutter_test/flutter_test.dart';
import 'package:nsfw_detector_flutter/src/nsfw_detector.dart';

void main() {
  group('NsfwResult', () {
    test('supports equality, hashCode, and toString', () {
      final first = NsfwResult(isNsfw: true, score: 0.87, safeScore: 0.13);
      final second = NsfwResult(isNsfw: true, score: 0.87, safeScore: 0.13);
      final different = NsfwResult(isNsfw: false, score: 0.87, safeScore: 0.13);

      expect(first, equals(second));
      expect(first.hashCode, equals(second.hashCode));
      expect(first, isNot(equals(different)));
      expect(
        first.toString(),
        'NsfwResult(isNsfw: true, score: 0.87, safeScore: 0.13)',
      );
    });

    test('safeScore and score sum to approximately 1.0', () {
      final result = NsfwResult(isNsfw: true, score: 0.87, safeScore: 0.13);
      expect(result.score + result.safeScore, closeTo(1.0, 1e-10));
    });

    test('classification returns correct category for score ranges', () {
      expect(
        NsfwResult(isNsfw: true, score: 0.8, safeScore: 0.2).classification,
        NsfwClassification.nsfw,
      );
      expect(
        NsfwResult(isNsfw: false, score: 0.5, safeScore: 0.5).classification,
        NsfwClassification.questionable,
      );
      expect(
        NsfwResult(isNsfw: false, score: 0.2, safeScore: 0.8).classification,
        NsfwClassification.safe,
      );
    });

    test('toJson returns correct map', () {
      final result = NsfwResult(isNsfw: true, score: 0.87, safeScore: 0.13);
      expect(result.toJson(), {
        'isNsfw': true,
        'score': 0.87,
        'safeScore': 0.13,
        'classification': 'nsfw',
      });
    });

    test('fromJson parses numeric values into a result', () {
      final result = NsfwResult.fromJson({
        'isNsfw': true,
        'score': 0.87,
        'safeScore': 0.13,
      });

      expect(result, NsfwResult(isNsfw: true, score: 0.87, safeScore: 0.13));
    });

    test('copyWith creates new instance with updated fields', () {
      final original = NsfwResult(isNsfw: true, score: 0.87, safeScore: 0.13);

      final withNewScore = original.copyWith(score: 0.5, safeScore: 0.5);
      expect(withNewScore.isNsfw, true);
      expect(withNewScore.score, 0.5);
      expect(withNewScore.safeScore, 0.5);
      expect(withNewScore, isNot(same(original)));

      final withNewIsNsfw = original.copyWith(isNsfw: false);
      expect(withNewIsNsfw.isNsfw, false);
      expect(withNewIsNsfw.score, 0.87);
      expect(withNewIsNsfw.safeScore, 0.13);
    });
  });

  group('NsfwDetector safety', () {
    test('isInitialized is false before initialize()', () {
      expect(NsfwDetector.isInitialized, isFalse);
    });

    test('instance getter throws StateError when not initialized', () {
      expect(
        () => NsfwDetector.instance,
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('NsfwDetector not initialized'),
          ),
        ),
      );
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
