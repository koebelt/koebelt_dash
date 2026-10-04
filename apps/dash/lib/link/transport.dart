import 'dart:async';
import 'dart:math' as math;

import 'protocol.dart';

/// A bidirectional message pipe to one device.
abstract class Transport {
  Stream<Msg> get messages;
  Future<void> open();
  void send(Msg m);
  Future<void> close();

  /// Short label shown in the UI: "Wi-Fi · 10.0.4.22".
  String get label;
}

/// In-memory pipe between the app and a simulated device, with a small
/// synthetic latency so latency readouts behave like a real link.
class LoopbackTransport implements Transport {
  LoopbackTransport(this.label);
  @override
  final String label;

  final _toApp = StreamController<Msg>.broadcast();
  final _toDevice = StreamController<Msg>.broadcast();
  final _rnd = math.Random();
  bool _closed = false;

  /// Extra one-way delay in ms, set by the device (grows with distance).
  double delayMs = 8;

  @override
  Stream<Msg> get messages => _toApp.stream;

  /// Device side.
  Stream<Msg> get deviceInbox => _toDevice.stream;

  void deviceSend(Msg m) => _deliver(_toApp, m);

  @override
  Future<void> open() async {}

  @override
  void send(Msg m) => _deliver(_toDevice, m);

  // Jittered latency, but in order per direction, like a serial or BLE link.
  final _clock = Stopwatch()..start();
  final _due = <StreamController<Msg>, int>{};

  void _deliver(StreamController<Msg> c, Msg m) {
    if (_closed) return;
    final now = _clock.elapsedMicroseconds;
    final at = math.max(now + ((delayMs + _rnd.nextDouble() * 3) * 1000).round(), (_due[c] ?? 0) + 1);
    _due[c] = at;
    Timer(Duration(microseconds: at - now), () {
      if (!_closed && !c.isClosed) c.add(m);
    });
  }

  @override
  Future<void> close() async {
    _closed = true;
    await _toApp.close();
    await _toDevice.close();
  }
}
