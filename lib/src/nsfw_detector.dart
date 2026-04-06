import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

/// Exception thrown when NSFW detection fails.
class NsfwDetectorException implements Exception {
  /// Creates a detector exception with an optional underlying cause.
  NsfwDetectorException(this.message, {this.cause, this.stackTrace});

  /// Human-readable error message.
  final String message;

  /// Original error that triggered this exception.
  final Object? cause;

  /// Stack trace captured at the failure site.
  final StackTrace? stackTrace;

  @override
  String toString() {
    final buffer = StringBuffer('NsfwDetectorException: $message');
    if (cause != null) {
      buffer.write('\nCause: $cause');
    }
    return buffer.toString();
  }
}

/// VggMean class defines the mean values for each channel used in the VGG model.
class VggMean {
  /// Mean value for the red channel
  static const red = 123.68;

  /// Mean value for the green channel
  static const green = 116.779;

  /// Mean value for the blue channel
  static const blue = 103.939;
}

/// Classification category for NSFW detection results.
enum NsfwClassification {
  /// Content is considered safe (score < 0.4).
  safe,

  /// Content is borderline (score >= 0.4 and < 0.7).
  questionable,

  /// Content is considered NSFW (score >= 0.7).
  nsfw,
}

/// NsfwResult class stores the results of the NSFW detection.
class NsfwResult {
  /// Indicates if the content is NSFW
  final bool isNsfw;

  /// The NSFW score of the image
  final double score;

  /// The safe score of the image
  final double safeScore;

  /// Constructor for creating an instance of NsfwResult
  NsfwResult({required this.isNsfw, required this.score, required this.safeScore});

  /// Classification based on the NSFW score.
  NsfwClassification get classification {
    if (score >= 0.7) return NsfwClassification.nsfw;
    if (score >= 0.4) return NsfwClassification.questionable;
    return NsfwClassification.safe;
  }

  /// Serializes this result to a JSON-compatible map.
  Map<String, dynamic> toJson() => {
    'isNsfw': isNsfw,
    'score': score,
    'safeScore': safeScore,
    'classification': classification.name,
  };

  /// Returns a copy of this result with the given fields replaced.
  NsfwResult copyWith({bool? isNsfw, double? score, double? safeScore}) {
    return NsfwResult(
      isNsfw: isNsfw ?? this.isNsfw,
      score: score ?? this.score,
      safeScore: safeScore ?? this.safeScore,
    );
  }

  @override
  String toString() {
    return 'NsfwResult(isNsfw: $isNsfw, score: $score, safeScore: $safeScore)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NsfwResult &&
        other.isNsfw == isNsfw &&
        other.score == score &&
        other.safeScore == safeScore;
  }

  @override
  int get hashCode => Object.hash(isNsfw, score, safeScore);
}

/// NsfwDetector class handles the NSFW detection process.
class NsfwDetector {
  /// Default input width for the model
  static const _kInputWidth = 224;

  /// Default input height for the model
  static const _kInputHeight = 224;

  /// Path to the TFLite model
  static const _kModelPath =
      'packages/nsfw_detector_flutter/assets/nsfw.tflite';

  /// Default threshold for classifying NSFW content
  static const _kNSFWThreshold = 0.7;

  /// Singleton instance
  static NsfwDetector? _instance;

  /// Whether the singleton has been initialized.
  static bool get isInitialized => _instance != null;

  /// Returns the singleton instance, throwing if not yet initialized.
  static NsfwDetector get instance {
    if (_instance == null) {
      throw StateError(
        'NsfwDetector not initialized. Call NsfwDetector.initialize() first.',
      );
    }
    return _instance!;
  }

  /// Initializes the singleton instance. No-op if already initialized.
  static Future<void> initialize({double threshold = _kNSFWThreshold}) async {
    if (_instance != null) return;
    _instance = await load(threshold: threshold);
  }

  /// Disposes the singleton instance and releases resources.
  static void disposeInstance() {
    _instance?.close();
    _instance = null;
  }

  /// Interpreter for running the TFLite model
  late final Interpreter _interpreter;

  /// Threshold for NSFW classification
  late final double _threshold;

  /// Whether this detector has been closed
  bool _isClosed = false;

  /// Whether an inference is currently running
  bool _isRunning = false;

  /// Private constructor for creating an instance of NsfwDetector
  NsfwDetector._create(this._interpreter, this._threshold);

  /// Closes the interpreter to release resources
  void close() {
    _isClosed = true;
    _interpreter.close();
  }

  /// Loads the NSFW detector with default parameters
  static Future<NsfwDetector> load({double threshold = _kNSFWThreshold}) async {
    _validateThreshold(threshold);

    try {
      final interpreter = await Interpreter.fromAsset(_kModelPath);
      return NsfwDetector._create(interpreter, threshold);
    } catch (error, stackTrace) {
      throw NsfwDetectorException(
        'Failed to load NSFW detector model from asset.',
        cause: error,
        stackTrace: stackTrace,
      );
    }
  }

  /// Detects NSFW content from a file
  Future<NsfwResult?> detectNSFWFromFile(File imageFile) async {
    if (_isClosed) throw StateError('NsfwDetector has been closed.');
    try {
      final imageData = await imageFile.readAsBytes();
      final image = img.decodeImage(imageData);
      return image == null ? null : await detectNSFWFromImage(image);
    } catch (error, stackTrace) {
      if (error is NsfwDetectorException) {
        rethrow;
      }
      throw NsfwDetectorException(
        'Failed to detect NSFW content from file: ${imageFile.path}',
        cause: error,
        stackTrace: stackTrace,
      );
    }
  }

  /// Detects NSFW content from bytes
  Future<NsfwResult?> detectNSFWFromBytes(Uint8List imageData) async {
    if (_isClosed) throw StateError('NsfwDetector has been closed.');
    try {
      final image = img.decodeImage(imageData);
      return image == null ? null : await detectNSFWFromImage(image);
    } catch (error, stackTrace) {
      if (error is NsfwDetectorException) {
        rethrow;
      }
      throw NsfwDetectorException(
        'Failed to detect NSFW content from image bytes.',
        cause: error,
        stackTrace: stackTrace,
      );
    }
  }

  /// Detects NSFW content from an image
  ///
  /// Inference runs synchronously on the calling isolate. Use `compute()`
  /// or another background isolate if you need to keep the UI responsive.
  Future<NsfwResult?> detectNSFWFromImage(img.Image image) async {
    if (_isClosed) throw StateError('NsfwDetector has been closed.');
    if (_isRunning) {
      throw StateError(
        'NsfwDetector is already running an inference. Concurrent calls are not supported.',
      );
    }
    _isRunning = true;
    try {
      final resizedImage = img.copyResize(
        image,
        width: _kInputWidth,
        height: _kInputHeight,
      );

      final inputBuffer = _imageToInputBuffer(resizedImage);
      final output = <List<double>>[List<double>.filled(2, 0.0)];

      _interpreter.run(inputBuffer, output);

      final result = output.first;
      if (result.length < 2) {
        throw NsfwDetectorException(
          'Model output has unexpected shape: expected at least 2 values.',
        );
      }

      final score = result[1];
      return NsfwResult(isNsfw: score > _threshold, score: score, safeScore: result[0]);
    } catch (error, stackTrace) {
      if (error is NsfwDetectorException) {
        rethrow;
      }
      throw NsfwDetectorException(
        'Failed to detect NSFW content from image.',
        cause: error,
        stackTrace: stackTrace,
      );
    } finally {
      _isRunning = false;
    }
  }

  /// Converts an image to the model's Float32 input buffer.
  ///
  /// The buffer is laid out as consecutive BGR pixels with VGG mean
  /// subtraction applied to each channel:
  /// `[blue - 103.939, green - 116.779, red - 123.68]`.
  Uint8List _imageToInputBuffer(img.Image image) {
    final buffer = Uint8List(_kInputWidth * _kInputHeight * 3 * 4);
    final byteBuffer = buffer.buffer;
    final imgData = Float32List.view(byteBuffer);

    int index = 0;
    for (var i = 0; i < _kInputHeight; i++) {
      for (var j = 0; j < _kInputWidth; j++) {
        var pixel = image.getPixel(j, i);
        imgData[index++] = (pixel.b - VggMean.blue).toDouble();
        imgData[index++] = (pixel.g - VggMean.green).toDouble();
        imgData[index++] = (pixel.r - VggMean.red).toDouble();
      }
    }

    return buffer;
  }

  /// Validates the requested threshold for tests and call-site reuse.
  @visibleForTesting
  static void validateThreshold(double threshold) {
    _validateThreshold(threshold);
  }

  static void _validateThreshold(double threshold) {
    if (threshold.isNaN ||
        threshold.isInfinite ||
        threshold < 0.0 ||
        threshold > 1.0) {
      throw ArgumentError.value(
        threshold,
        'threshold',
        'Must be a finite value between 0.0 and 1.0.',
      );
    }
  }

  /// Runs NSFW detection in a background isolate via [compute].
  ///
  /// Loads a fresh interpreter in the background isolate, runs detection,
  /// and closes the interpreter before returning the result.
  static Future<NsfwResult?> detectBytesInBackground(
    Uint8List imageData, {
    double threshold = _kNSFWThreshold,
  }) {
    _validateThreshold(threshold);
    return compute(_detectInIsolate, _IsolatePayload(imageData, threshold));
  }
}

class _IsolatePayload {
  final Uint8List imageData;
  final double threshold;
  _IsolatePayload(this.imageData, this.threshold);
}

Future<NsfwResult?> _detectInIsolate(_IsolatePayload payload) async {
  final detector = await NsfwDetector.load(threshold: payload.threshold);
  try {
    return await detector.detectNSFWFromBytes(payload.imageData);
  } finally {
    detector.close();
  }
}
