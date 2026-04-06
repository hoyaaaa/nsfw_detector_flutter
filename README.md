# 🙈 nsfw_detector_flutter

<p>
    <a href="https://pub.dev/packages/nsfw_detector_flutter">
        <img src="https://img.shields.io/pub/v/nsfw_detector_flutter" alt="pub package">
    </a>
    <a href="https://pub.dev/packages/nsfw_detector_flutter">
        <img src="https://img.shields.io/pub/likes/nsfw_detector_flutter" alt="pub package">
    </a>
    <a href="https://pub.dev/packages/nsfw_detector_flutter">
        <img src="https://img.shields.io/pub/popularity/nsfw_detector_flutter" alt="pub package">
    </a>
    <a href="https://img.shields.io/github/license/hoyaaaa/nsfw_detector_flutter">
        <img src="https://img.shields.io/github/license/hoyaaaa/nsfw_detector_flutter" alt="License">
    </a>
    <a href="https://github.com/hoyaaaa/nsfw_detector_flutter/issues">
        <img src="https://img.shields.io/github/issues/hoyaaaa/nsfw_detector_flutter" alt="GitHub issues">
    </a>
</p>

A Flutter package to detect NSFW 🔞 (Not Safe For Work / NUDE / adults) contents and classify SAFE 🛡️ contents __without downloading or setting any assets__

## 🛠️ Installation

```sh
flutter pub add nsfw_detector_flutter
```

That's it! You don't need any assets. 😎

## 🏃 Simple usage

```dart
import 'package:nsfw_detector_flutter/nsfw_detector_flutter.dart';

// Use the singleton instance
await NsfwDetector.initialize();
NsfwDetector detector = NsfwDetector.instance;

File imageFile = File('path/to/image.jpg');
NsfwResult? result = await detector.detectNSFWFromFile(imageFile);

// whether it is over threshold (default: 0.7)
print("NSFW detected: ${result?.isNsfw}");
// float value from 0 to 1
print("NSFW score: ${result?.score}");
print("Safe score: ${result?.safeScore}");
print("Classification: ${result?.classification.name}");

// Clean up resources when done
NsfwDetector.disposeInstance();
```

## 📙 Usage

### Load and initialize the detector

The `NsfwDetector` can be initialized and accessed as a singleton, or instantiated via `load()`:

```dart
// Singleton usage (Recommended)
await NsfwDetector.initialize(threshold: 0.7);
NsfwDetector detector = NsfwDetector.instance;

// ... later when done ...
NsfwDetector.disposeInstance();

// Or instantiate directly
NsfwDetector detector = await NsfwDetector.load(); // default threshold: 0.7
```

| Parameter     | Type    | Default | Description                                                   |
|---------------|---------|---------|---------------------------------------------------------------|
| `threshold`   | Float   | 0.7     | The threshold to classify an image as NSFW                    |                              |

### NsfwResult

The `NsfwResult` class contains the following properties and methods:

| Property         | Type                 | Description                                                   |
|------------------|----------------------|---------------------------------------------------------------|
| `score`          | double               | The NSFW score of the image (0 to 1, higher indicates more NSFW) |
| `safeScore`      | double               | The safe score of the image (0 to 1)                          |
| `isNsfw`         | bool                 | Indicates if the image is classified as NSFW based on the threshold |
| `classification` | `NsfwClassification` | An enum (`safe`, `questionable`, `nsfw`) based on the score   |

It also includes standard methods for serialization and object copying:
- `toJson()`: Serializes the result to a JSON map.
- `fromJson(Map<String, dynamic> json)`: Creates a result from a JSON object.
- `copyWith(...)`: Returns a copy of the result with updated properties.

### Detect NSFW content

```dart
// from bytes
final ByteData data = await rootBundle.load('assets/nsfw.jpeg');
final Uint8List imageData = data.buffer.asUint8List();
NsfwResult? result = await detector.detectNSFWFromBytes(imageData);

// detect in background isolate
NsfwResult? resultInBackground = await NsfwDetector.detectBytesInBackground(imageData);

// from file
File imageFile = File('path/to/image.jpg');
NsfwResult? resultFile = await detector.detectNSFWFromFile(imageFile);

// from XFile (cross_file)
import 'package:cross_file/cross_file.dart';
XFile xFile = XFile('path/to/image.jpg');
NsfwResult? resultXFile = await detector.detectNSFWFromXFile(xFile);

// from batch
List<Uint8List> images = [imageData1, imageData2];
List<NsfwResult?> results = await detector.detectBatch(images);

// from URL
Uri url = Uri.parse('https://example.com/image.jpg');
NsfwResult? resultUrl = await detector.detectNSFWFromUrl(url); // Redirects are followed, 10s timeout

// from image
import 'package:image/image.dart' as img;

img.Image image = img.decodeImage(File('path/to/image.jpg').readAsBytesSync())!;
NsfwResult? resultImage = await detector.detectNSFWFromImage(image);
```

## ⚠️ Warnings

### iOS

If there are issues related to the library on iOS and it doesn't work, check the following setting in XCode:

1. Ensure that **XCode > Build Settings > Deployment > Strip Linked Product** is set to **No**.

**Note on HEIC limitation for iOS**: Image formats like HEIC (which are the default camera format on iOS) may not be fully supported depending on the iOS version and internal decoding libraries by the `image` package. It is recommended to convert them to JPEG or PNG before processing.

### Android

#### 1.	Min SDK Version:

This package uses the `tflite_flutter` package, so the Android `minSdkVersion` must be set to 26 or higher. Check and update the following in your `android/app/build.gradle` file:

```gradle
android {
    defaultConfig {
        minSdkVersion 26
    }
}
```

#### 2.	ProGuard / R8 Configuration:

If you encounter issues during release builds due to R8 (ProGuard), ensure that the following rules are added to your `android/app/proguard-rules.pro` file:

```pro
# TensorFlow Lite GPU Delegate
-keep class org.tensorflow.lite.gpu.GpuDelegateFactory$Options { *; }
-dontwarn org.tensorflow.lite.gpu.GpuDelegateFactory$Options
```

Also, verify that ProGuard or R8 is enabled in your `android/app/build.gradle` file:

```gradle
buildTypes {
    release {
        minifyEnabled true
        shrinkResources true
        proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
    }
}
```

## 🧪 Test

For information on how to run integration tests for this package, please refer to the [example README](example/README.md).

## 💳 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

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