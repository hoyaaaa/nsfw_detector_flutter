# nsfw_detector_flutter Example

This is an example application to demonstrate how to use the `nsfw_detector_flutter` package.

## Integration Test

This package requires native libraries to run, and different libraries are needed for different platforms. Therefore, platform-specific tests are necessary. An example has been created to perform integration tests.

Run the integration tests:

```sh
flutter drive --driver=test_driver/integration_test_driver.dart --target=integration_test/native_test.dart
```