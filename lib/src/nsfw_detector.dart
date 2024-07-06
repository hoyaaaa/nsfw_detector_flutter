import 'dart:io';

import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'dart:typed_data';

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
  NsfwResult(this.isNsfw, this.score);
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

  /// Threshold for classifying NSFW content
  static const _kNSFWThreshold = 0.7;

  /// Interpreter for running the TFLite model
  late final Interpreter _interpreter;

  /// Threshold for NSFW classification
  late final double _threshold;

  /// Input width for the model
  late final int _inputWidth;

  /// Input height for the model
  late final int _inputHeight;

  /// Private constructor for creating an instance of NsfwDetector
  NsfwDetector._create(
      this._interpreter, this._threshold, this._inputWidth, this._inputHeight);

  /// Closes the interpreter to release resources
  void close() {
    _interpreter.close();
  }

  /// Loads the NSFW detector with default parameters
  static Future<NsfwDetector> load(
      {double threshold = _kNSFWThreshold,
      int inputWidth = _kInputWidth,
      int inputHeight = _kInputHeight}) async {
    final interpreter = await Interpreter.fromAsset(_kModelPath);
    return NsfwDetector._create(
        interpreter, threshold, inputWidth, inputHeight);
  }

  /// Loads the NSFW detector from a custom model asset path
  static Future<NsfwDetector> loadFromAsset(String modelAssetPath,
      {double threshold = _kNSFWThreshold,
      int inputWidth = _kInputWidth,
      int inputHeight = _kInputHeight}) async {
    final interpreter = await Interpreter.fromAsset(modelAssetPath);
    return NsfwDetector._create(
        interpreter, threshold, inputWidth, inputHeight);
  }

  /// Loads the NSFW detector from a model file
  static Future<NsfwDetector> loadFromFile(File modelFile,
      {double threshold = _kNSFWThreshold,
      int inputWidth = _kInputWidth,
      int inputHeight = _kInputHeight}) async {
    final interpreter = Interpreter.fromFile(modelFile);
    return NsfwDetector._create(
        interpreter, threshold, inputWidth, inputHeight);
  }

  /// Detects NSFW content from a file
  Future<NsfwResult?> detectNSFWFromFile(File imageFile) async {
    final image = img.decodeJpg(imageFile.readAsBytesSync());
    return image == null ? null : await detectNSFWFromImage(image);
  }

  /// Detects NSFW content from bytes
  Future<NsfwResult?> detectNSFWFromBytes(Uint8List imageData) async {
    final image = img.decodeImage(imageData);
    return image == null ? null : await detectNSFWFromImage(image);
  }

  /// Detects NSFW content from an image
  Future<NsfwResult?> detectNSFWFromImage(img.Image image) async {
    img.Image resizedImage =
        img.copyResize(image, width: _kInputWidth, height: _kInputHeight);

    Uint8List input = _imageToByteList(resizedImage);
    final output = List.filled(1 * 2, 0.0).reshape([1, 2]);

    _interpreter.run(input, output);

    List<double> result = output.first ?? [];
    double? score;
    if (result.length == 2) {
      score = result[1];
    }
    return score == null ? null : NsfwResult(score > _threshold, score);
  }

  /// Converts an image to a byte list suitable for the model input
  Uint8List _imageToByteList(img.Image image) {
    final buffer = Uint8List(_inputWidth * _inputHeight * 3 * 4);
    final byteBuffer = buffer.buffer;
    final imgData = Float32List.view(byteBuffer);

    int index = 0;
    for (var i = 0; i < _inputHeight; i++) {
      for (var j = 0; j < _inputWidth; j++) {
        var pixel = image.getPixel(j, i);
        imgData[index++] = (pixel.b - VggMean.blue).toDouble();
        imgData[index++] = (pixel.g - VggMean.green).toDouble();
        imgData[index++] = (pixel.r - VggMean.red).toDouble();
      }
    }

    return buffer;
  }
}
