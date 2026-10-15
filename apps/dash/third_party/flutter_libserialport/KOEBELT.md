# Vendored: flutter_libserialport 0.6.0

From https://pub.dev/packages/flutter_libserialport (MIT; libserialport in
`third_party/` is LGPL-3.0), used through `dependency_overrides` in
`apps/dash/pubspec.yaml`. Removed: `example/`, `doc/`.

Changed:
- `android/build.gradle`: `jcenter()` (gone from Gradle 9) is `mavenCentral()`.

Drop this copy for the pub.dev package once a release fixes it upstream.
