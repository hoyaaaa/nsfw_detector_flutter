# Changelog

## [1.1.0] - 2026-04-06
### Breaking Changes
- `NsfwResult` constructor now uses named required parameters: `NsfwResult(isNsfw: ..., score: ..., safeScore: ...)`.

### Added
- `NsfwResult.safeScore` — exposes the model's safe-class probability alongside `score`.
- `NsfwClassification` enum (`safe`, `questionable`, `nsfw`) and `NsfwResult.classification` getter.
- `NsfwResult.toJson()`, `NsfwResult.fromJson()`, `NsfwResult.copyWith()`.
- `NsfwDetector.initialize()` / `NsfwDetector.instance` / `NsfwDetector.disposeInstance()` singleton API.
- `NsfwDetector.detectBytesInBackground()` — runs detection in a background isolate via `compute()`.
- `NsfwDetector.detectNSFWFromXFile(XFile)` — direct support for `image_picker` / `camera` output.
- `NsfwDetector.detectNSFWFromUrl(Uri)` — detects NSFW from a network image URL (10s timeout).
- `NsfwDetector.detectBatch(List<Uint8List>)` — scans multiple images in one call.
- `NsfwDetector.load(useGpu: true)` — optional GPU delegate with automatic CPU fallback.
- `NsfwDetectorException` — structured exception wrapping all detector errors with `cause` and `stackTrace`.

### Fixed
- `detectNSFWFromFile` was silently returning `null` for non-JPEG formats (was using `decodeJpg`; now uses `decodeImage`).
- `detectNSFWFromFile` was blocking the UI thread with synchronous file I/O (now uses `await readAsBytes()`).
- Calling detect methods after `close()` now throws a `StateError` instead of crashing natively.
- Concurrent inference on the same instance now throws a `StateError` instead of producing undefined behavior.
- `threshold` parameter now validates range (rejects NaN, infinity, values outside 0.0–1.0).
- Empty `Uint8List` input to `detectNSFWFromBytes` now throws `ArgumentError` instead of returning `null`.

### Changed
- Flutter SDK constraint tightened to `>=3.10.0` (was `>=1.17.0`).

## [1.0.5] - 2025-01-23
### Updated
- Updated README to include Android ProGuard settings.

## [1.0.4] - 2024-07-06
### Added
- This version was skipped (internal release).

## [1.0.3] - 2024-07-06
### Updated
- Updated documentation to read easily.

## [1.0.2] - 2024-07-06
### Updated
- Updated documentation to include new parameters for NSFW classification.

## [1.0.1] - 2024-07-06
### Added
- Updated documentation for `NsfwDetector` and related classes.
- Added detailed comments and explanations for each method and member variable.

### Changed
- Updated `image` package to the latest version for improved performance and compatibility.

## [1.0.0] - 2024-07-06
### Added
- Initial release of `nsfw_detector_flutter`.
- NSFW detection functionality using TensorFlow Lite.
- Support for detecting NSFW content from image bytes, files, and `image` package objects.
- Example application demonstrating usage.
- Integration tests for Android and iOS.
