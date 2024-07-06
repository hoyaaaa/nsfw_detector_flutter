# nsfw_detector_flutter

A Flutter package to detect NSFW (Not Safe For Work) content in images using TensorFlow Lite.

## Features

- Detect NSFW content in images.
- Provide NSFW score and classification.

## Supported Platforms

- Android
- iOS

## Installation

### From pub.dev

To use this package from pub.dev, run `pub add` command.

```sh
flutter pub add nsfw_detector_flutter
```

### From git repository

To use this package, add `nsfw_detector_flutter` as a dependency in your `pubspec.yaml` file.

```yaml
dependencies:
  flutter:
    sdk: flutter
  nsfw_detector_flutter:
    path: ../nsfw_detector_flutter
```

Then, run `flutter pub get` to install the package.

## Warnings

### iOS

If there are issues related to the library on iOS and it doesn't work, check the following setting in XCode:

1. Ensure that **XCode > Build Settings > Deployment > Strip Linked Product** is set to **No**.

### Android

This package uses the `flutter_lints` package, so the Android `minSdkVersion` must be set to 26 or higher. Check the following setting in the `android/app/build.gradle` file:

```gradle
android {
    defaultConfig {
        minSdkVersion 26
    }
}
```

## Usage

### Import the package

```dart
import 'package:nsfw_detector_flutter/nsfw_detector_flutter.dart';
```

### Load and initialize the detector

The `NsfwDetector` can be initialized with default parameters:

```dart
NsfwDetector detector = await NsfwDetector.load();
```

### Load and initialize the detector with parameters

You can customize the detector initialization with the following parameters:

- `threshold`: The threshold to classify an image as NSFW. Default is `0.7`.
- `inputWidth`: The input width for the model. Default is `224`.
- `inputHeight`: The input height for the model. Default is `224`.

Note: The default values for `inputWidth` and `inputHeight` are set to `224` to match the provided model. If you are using the provided model, you can use the default values. If you want to use a different model, you should specify the correct dimensions.

```dart
NsfwDetector detector = await NsfwDetector.load(threshold: 0.8, inputWidth: 256, inputHeight: 256);
```

### Load a custom model from asset or file

If you want to use a different model, you can load it from an asset or file:

```dart
NsfwDetector detectorFromAsset = await NsfwDetector.loadFromAsset('path/to/custom_model.tflite');
NsfwDetector detectorFromFile = await NsfwDetector.loadFromFile(File('path/to/custom_model.tflite'));
```

### Detect NSFW content from bytes

```dart
final ByteData data = await rootBundle.load('assets/nsfw.jpeg');
final Uint8List imageData = data.buffer.asUint8List();

NsfwResult? result = await detector.detectNSFWFromBytes(imageData);

print("NSFW score: ${result?.score}");
print("NSFW detected: ${result?.isNsfw}");
```

### Detect NSFW content from file

```dart
File imageFile = File('path/to/image.jpg');
NsfwResult? result = await detector.detectNSFWFromFile(imageFile);

print("NSFW score: ${result?.score}");
print("NSFW detected: ${result?.isNsfw}");
```

### Detect NSFW content from image

```dart
import 'package:image/image.dart' as img;

img.Image image = img.decodeImage(File('path/to/image.jpg').readAsBytesSync())!;
NsfwResult? result = await detector.detectNSFWFromImage(image);

print("NSFW score: ${result?.score}");
print("NSFW detected: ${result?.isNsfw}");
```

### Example

Here is a full example of how to use the `nsfw_detector_flutter` package in a Flutter application.

```dart
import 'package:flutter/material.dart';
import 'package:nsfw_detector_flutter/nsfw_detector_flutter.dart';
import 'package:flutter/services.dart';
import 'dart:io';
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
```

### NsfwResult

The `NsfwResult` class contains the following properties:

- `score`: The NSFW score of the image. This is a value between 0 and 1, where a higher score indicates a higher likelihood that the image is NSFW.
- `isNsfw`: A boolean indicating whether the image is classified as NSFW based on the specified threshold.

### Model Information

The default model used in this package is referenced from the [open_nsfw_android](https://github.com/devzwy/open_nsfw_android) repository, which is a port of the [yahoo/open_nsfw](https://github.com/yahoo/open_nsfw) model. This package complies with the license terms of the yahoo/open_nsfw repository.

### BSD 3-Clause License

```
Copyright 2016, Yahoo Inc.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
Neither the name of the Yahoo Inc. nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
```

### Integration Test

For information on how to run integration tests for this package, please refer to the [example README](example/README.md).

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
