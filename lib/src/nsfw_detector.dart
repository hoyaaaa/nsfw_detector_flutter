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

/// NsfwResult class stores the results of the NSFW detection.
class NsfwResult {
  /// Indicates if the content is NSFW
  final bool isNsfw;

  /// The NSFW score of the image
  final double score;

  /// Constructor for creating an instance of NsfwResult
  NsfwResult({required this.isNsfw, required this.score});

  @override
  String toString() {
    return 'NsfwResult(isNsfw: $isNsfw, score: $score)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NsfwResult &&
        other.isNsfw == isNsfw &&
        other.score == score;
  }

  @override
  int get hashCode => Object.hash(isNsfw, score);
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

  /// Interpreter for running the TFLite model
  late final Interpreter _interpreter;

  /// Threshold for NSFW classification
  late final double _threshold;

  /// Private constructor for creating an instance of NsfwDetector
  NsfwDetector._create(this._interpreter, this._threshold);

  /// Closes the interpreter to release resources
  void close() {
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
      return NsfwResult(isNsfw: score > _threshold, score: score);
    } catch (error, stackTrace) {
      if (error is NsfwDetectorException) {
        rethrow;
      }
      throw NsfwDetectorException(
        'Failed to detect NSFW content from image.',
        cause: error,
        stackTrace: stackTrace,
      );
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
}
