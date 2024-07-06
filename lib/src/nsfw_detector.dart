import 'dart:io';

import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'dart:typed_data';

class VggMean {
  static const red = 123.68;
  static const green = 116.779;
  static const blue = 103.939;
}

class NsfwResult {
  final bool isNsfw;
  final double score;

  NsfwResult(this.isNsfw, this.score);
}

class NsfwDetector {
  static const _kInputWidth = 224;
  static const _kInputHeight = 224;
  static const _kModelPath = 'packages/nsfw_detector_flutter/assets/nsfw.tflite'; // original path: "assets/nsfw.tflite"
  static const _kNSFWThreshold = 0.7;

  late final Interpreter _interpreter;
  late final double _threshold;
  late final int _inputWidth;
  late final int _inputHeight;

  NsfwDetector._create(this._interpreter, this._threshold, this._inputWidth, this._inputHeight);

  void close() {
    _interpreter.close();
  }

  static Future<NsfwDetector> load({double threshold = _kNSFWThreshold, int inputWidth = _kInputWidth, int inputHeight = _kInputHeight}) async {
    final interpreter = await Interpreter.fromAsset(_kModelPath);
    return NsfwDetector._create(interpreter, threshold, inputWidth, inputHeight);
  }

  static Future<NsfwDetector> loadFromAsset(String modelAssetPath, {double threshold = _kNSFWThreshold, int inputWidth = _kInputWidth, int inputHeight = _kInputHeight}) async {
    final interpreter = await Interpreter.fromAsset(modelAssetPath);
    return NsfwDetector._create(interpreter, threshold, inputWidth, inputHeight);
  }

  static Future<NsfwDetector> loadFromFile(File modelFile, {double threshold = _kNSFWThreshold, int inputWidth = _kInputWidth, int inputHeight = _kInputHeight}) async {
    final interpreter = Interpreter.fromFile(modelFile);
    return NsfwDetector._create(interpreter, threshold, inputWidth, inputHeight);
  }

  Future<NsfwResult?> detectNSFWFromFile(File imageFile) async {
    final image = img.decodeJpg(imageFile.readAsBytesSync());
    return image == null ? null : await detectNSFWFromImage(image);
  }

  Future<NsfwResult?> detectNSFWFromBytes(Uint8List imageData) async {
    final image = img.decodeImage(imageData);
    return image == null ? null : await detectNSFWFromImage(image);
  }

  Future<NsfwResult?> detectNSFWFromImage(img.Image image) async {
    img.Image resizedImage = img.copyResize(image, width: _kInputWidth, height: _kInputHeight);

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
