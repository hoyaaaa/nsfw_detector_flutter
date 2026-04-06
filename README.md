# 🙈 nsfw_detector_flutter

<p>
    <a href="https://pub.dev/packages/nsfw_detector_flutter">
        <img src="https://img.shields.io/pub/v/nsfw_detector_flutter" alt="pub version">
    </a>
    <a href="https://pub.dev/packages/nsfw_detector_flutter/score">
        <img src="https://img.shields.io/pub/points/nsfw_detector_flutter" alt="pub points">
    </a>
    <a href="https://pub.dev/packages/nsfw_detector_flutter">
        <img src="https://img.shields.io/pub/likes/nsfw_detector_flutter" alt="pub likes">
    </a>
    <a href="https://pub.dev/packages/nsfw_detector_flutter">
        <img src="https://img.shields.io/pub/popularity/nsfw_detector_flutter" alt="pub popularity">
    </a>
    <a href="https://pub.dev/packages/nsfw_detector_flutter">
        <img src="https://img.shields.io/badge/platform-android%20%7C%20ios-lightgrey" alt="platform">
    </a>
    <a href="https://github.com/hoyaaaa/nsfw_detector_flutter/blob/main/LICENSE">
        <img src="https://img.shields.io/github/license/hoyaaaa/nsfw_detector_flutter" alt="license">
    </a>
    <a href="https://github.com/hoyaaaa/nsfw_detector_flutter/issues">
        <img src="https://img.shields.io/github/issues/hoyaaaa/nsfw_detector_flutter" alt="GitHub issues">
    </a>
</p>

On-device NSFW image detection for Flutter — no internet, no server, no extra assets required. Powered by the [Yahoo/open_nsfw](https://github.com/yahoo/open_nsfw) TensorFlow Lite model.

## ✨ Features

- 🔒 **100% on-device** — no images ever leave the user's device
- 📦 **Zero setup** — model is bundled, no extra download needed
- 🎯 **Confidence score** — raw NSFW/safe scores (0.0–1.0) + three-tier classification
- ⚡ **Background isolate** — `detectBytesInBackground()` for UI-safe detection
- 🖼️ **Multiple input sources** — File, bytes, XFile, URL, `package:image` Image
- 🗂️ **Batch processing** — scan multiple images in one call
- 🎮 **GPU acceleration** — optional GPU delegate with automatic CPU fallback
- 🔄 **Singleton support** — share one detector instance across your app

## 📋 Requirements

| Platform | Minimum version |
|----------|----------------|
| Android  | SDK 26+ (API level 26) |
| iOS      | Xcode with "Strip Linked Product" set to **No** |
| Flutter  | 3.10.0+ |
| Dart     | 3.3.1+ |

## 🛠️ Installation

```sh
flutter pub add nsfw_detector_flutter
```

Then follow the [platform setup](#%EF%B8%8F-platform-setup) steps below.

## 🚀 Quick Start

```dart
import 'package:nsfw_detector_flutter/nsfw_detector_flutter.dart';

// Initialize once (e.g., in main() or app startup)
await NsfwDetector.initialize();

// Detect from anywhere in your app
final result = await NsfwDetector.instance.detectNSFWFromBytes(imageBytes);

if (result != null) {
  print(result.isNsfw);           // true / false (based on threshold)
  print(result.score);            // 0.0–1.0  (NSFW probability)
  print(result.safeScore);        // 0.0–1.0  (safe probability)
  print(result.classification);   // NsfwClassification.safe / .questionable / .nsfw
}

// Release resources when the app closes
NsfwDetector.disposeInstance();
```

## 📖 API Reference

### Initialization

#### Singleton (recommended for most apps)

```dart
// Initialize once at startup — idempotent, safe to call multiple times
await NsfwDetector.initialize();                    // default threshold: 0.7
await NsfwDetector.initialize(threshold: 0.8);     // stricter threshold

// Check initialization state
print(NsfwDetector.isInitialized); // true

// Access the shared instance
final detector = NsfwDetector.instance;

// Release when done (e.g., app lifecycle dispose)
NsfwDetector.disposeInstance();
```

#### Direct instantiation

```dart
// Create your own instance (you manage its lifecycle)
final detector = await NsfwDetector.load();
final detectorGpu = await NsfwDetector.load(useGpu: true); // GPU-accelerated

// Always close when done to release native memory
detector.close();
```

| Parameter   | Type   | Default | Description |
|-------------|--------|---------|-------------|
| `threshold` | double | `0.7`   | Minimum NSFW score to classify as NSFW. Must be 0.0–1.0. |
| `useGpu`    | bool   | `false` | Use GPU delegate (Android/iOS). Falls back to CPU on failure. |

---

### Detection Methods

All methods return `NsfwResult?`. Returns `null` if the image could not be decoded (unsupported format). Throws `NsfwDetectorException` on infrastructure failures (file not found, network error, etc.).

| Method | Input | Notes |
|--------|-------|-------|
| `detectNSFWFromBytes(Uint8List)` | Raw image bytes | Supports JPEG, PNG, WebP, BMP, GIF |
| `detectNSFWFromFile(File)` | `dart:io` File | Async file read + decode |
| `detectNSFWFromXFile(XFile)` | `package:cross_file` XFile | Compatible with `image_picker`, `camera` |
| `detectNSFWFromUrl(Uri)` | HTTP/HTTPS URL | 10s timeout, follows redirects |
| `detectNSFWFromImage(img.Image)` | `package:image` Image | Pre-decoded image |
| `detectBatch(List<Uint8List>)` | List of byte arrays | Sequential, returns `List<NsfwResult?>` |
| `detectBytesInBackground(Uint8List)` | Raw image bytes | **Static.** Runs in background isolate via `compute()` |

#### Examples

```dart
import 'dart:io';
import 'package:cross_file/cross_file.dart';

final detector = NsfwDetector.instance;

// From file
final result = await detector.detectNSFWFromFile(File('/path/to/image.jpg'));

// From asset bytes
final data = await rootBundle.load('assets/photo.jpg');
final result = await detector.detectNSFWFromBytes(data.buffer.asUint8List());

// From image_picker / camera (XFile)
final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
if (pickedFile != null) {
  final result = await detector.detectNSFWFromXFile(pickedFile);
}

// From URL
final result = await detector.detectNSFWFromUrl(
  Uri.parse('https://example.com/photo.jpg'),
);

// Batch scan (e.g., gallery images before upload)
final results = await detector.detectBatch([bytes1, bytes2, bytes3]);

// Background isolate — keeps UI thread smooth
final result = await NsfwDetector.detectBytesInBackground(
  imageBytes,
  threshold: 0.7,
);
```

---

### NsfwResult

```dart
final result = await detector.detectNSFWFromBytes(imageBytes);

result.isNsfw;           // bool   — true if score > threshold
result.score;            // double — NSFW probability (0.0–1.0)
result.safeScore;        // double — safe probability (0.0–1.0); score + safeScore ≈ 1.0
result.classification;   // NsfwClassification enum (see below)

result.toJson();         // Map<String, dynamic>
result.copyWith(score: 0.9);  // NsfwResult with updated fields

// Reconstruct from JSON
final restored = NsfwResult.fromJson(json);
```

---

### NsfwClassification

Three-tier classification based on the NSFW score:

| Value | Score range | Meaning |
|-------|-------------|---------|
| `NsfwClassification.safe` | < 0.4 | Clearly safe content |
| `NsfwClassification.questionable` | 0.4 – 0.7 | Borderline / suggestive content |
| `NsfwClassification.nsfw` | ≥ 0.7 | Likely NSFW content |

```dart
switch (result.classification) {
  case NsfwClassification.safe:
    // show content normally
  case NsfwClassification.questionable:
    // blur or prompt user
  case NsfwClassification.nsfw:
    // block content
}
```

---

### Error Handling

```dart
try {
  final result = await detector.detectNSFWFromFile(imageFile);
} on NsfwDetectorException catch (e) {
  print(e.message);   // human-readable description
  print(e.cause);     // original underlying error
} on StateError catch (e) {
  // detector was closed, or concurrent inference attempted
  print(e.message);
} on ArgumentError catch (e) {
  // e.g. empty bytes, invalid threshold
  print(e.message);
}
```

---

## ⚙️ Platform Setup

### Android

**1. Minimum SDK version**

In `android/app/build.gradle`:

```gradle
android {
    defaultConfig {
        minSdkVersion 26
    }
}
```

**2. ProGuard / R8 rules**

Add to `android/app/proguard-rules.pro`:

```pro
# TensorFlow Lite GPU Delegate
-keep class org.tensorflow.lite.gpu.GpuDelegateFactory$Options { *; }
-dontwarn org.tensorflow.lite.gpu.GpuDelegateFactory$Options
```

Enable ProGuard in `android/app/build.gradle`:

```gradle
buildTypes {
    release {
        minifyEnabled true
        shrinkResources true
        proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
    }
}
```

---

### iOS

In **Xcode → Build Settings → Deployment → Strip Linked Product**, set to **No**.

---

## ⚠️ Known Limitations

### HEIC images (iOS)

HEIC is the default camera format on iOS, but the `image` package does not support it. Calling any detect method with a HEIC file will return `null` without throwing.

**Workaround:** Convert to JPEG before passing to the detector. With `image_picker`, use `imageQuality` parameter or configure `preferredCameraDevice` to capture in JPEG.

### Concurrent inference

A single `NsfwDetector` instance does not support concurrent calls. Calling a detect method while another is already running throws a `StateError`. For concurrent use, create multiple instances or use `detectBytesInBackground()` which creates its own isolate-local instance.

### App size

The bundled TFLite model adds ~22 MB to your APK/IPA. This is a one-time cost and does not require any network downloads at runtime.

---

## 🧪 Testing

Run integration tests on a physical device or emulator:

```sh
cd example
flutter test integration_test/native_test.dart
```

See [example/README.md](example/README.md) for more details.

---

## 💳 License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.

### Model

The bundled model is derived from [yahoo/open_nsfw](https://github.com/yahoo/open_nsfw) via [open_nsfw_android](https://github.com/devzwy/open_nsfw_android), licensed under the BSD 3-Clause License.

<details>
<summary>BSD 3-Clause License (Yahoo)</summary>

```
Copyright 2016, Yahoo Inc.

Redistribution and use in source and binary forms, with or without modification,
are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice,
   this list of conditions and the following disclaimer.
2. Redistributions in binary form must reproduce the above copyright notice,
   this list of conditions and the following disclaimer in the documentation
   and/or other materials provided with the distribution.
3. Neither the name of Yahoo Inc. nor the names of its contributors may be
   used to endorse or promote products derived from this software without
   specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
POSSIBILITY OF SUCH DAMAGE.
```

</details>
