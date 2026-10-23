import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:koebelt_dash/link/protocol.dart';

void main() {
  // appVersion is a const (it is in the handshake and the map tiles'
  // User-Agent), so nothing ties it to the build; this does. It may carry a
  // pre-release (1.3.0-beta.1); pubspec.yaml keeps the numbers, which iOS and
  // macOS require. The release workflow tags from appVersion.
  test('appVersion matches pubspec.yaml', () {
    final m = RegExp(r'^version:\s*([0-9.]+)\+', multiLine: true).firstMatch(File('pubspec.yaml').readAsStringSync());
    expect(appVersion.split('-').first, m!.group(1), reason: 'bump appVersion in lib/link/protocol.dart with pubspec.yaml');
    expect(appVersion, matches(RegExp(r'^\d+\.\d+\.\d+(-(alpha|beta|rc)\.\d+)?$')));
  });
}
