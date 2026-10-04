# koebelt dash · app

Flutter app for iOS, Android, macOS, Windows and Linux.

```bash
flutter run -d macos          # or: ios, android, windows, linux
flutter test                  # unit, session and interop tests
CAPTURE_DIR=/tmp/shots flutter test test/capture_test.dart   # render every screen
```

## Layout

| Path | What |
|------|------|
| `lib/theme/tokens.dart` | KOEBELT design tokens (colours, type, spacing, motion) |
| `lib/ui/` | Design-system components (Button, Badge, Tag, Switch, Notice, Dialog, Tabs, Seg, Readout…) and Lucide icons |
| `lib/core/dash.dart` | App state: connection, control, stop, failsafe test, recording and replay, params, pairing |
| `lib/core/telemetry.dart` | The app's view of a device, built from protocol messages; 10 s history buffers |
| `lib/link/` | Protocol codec, session (handshake, 20 Hz heartbeat, ping), UDP, BLE and USB serial transports, discovery |
| `lib/sim/` | Simulated devices (drone, rover, arm, rocket, bench) speaking the real protocol |
| `lib/viz/` | Canvas painters: 3D scene, line chart, attitude, radar, track map, joints |
| `lib/screens/` | Live, Control, Tune, Replay, Devices, Guides, Settings |

## Transports per platform

| | Simulator | Wi-Fi (UDP) | BLE | USB serial |
|---|---|---|---|---|
| iOS | yes | yes | yes | no |
| Android | yes | yes | yes | yes |
| macOS / Windows / Linux | yes | yes | yes | yes |

## Notes

- Building for macOS needs CocoaPods (`brew install cocoapods`) because the USB
  serial plugin ships as a pod.
- USB serial uses `flutter_libserialport` (MIT), which bundles `libserialport`
  (LGPL-3.0, dynamically linked).
- BLE uses `universal_ble` (BSD-3).
- Fonts are bundled under `assets/fonts` (SIL OFL), so the app works offline.
