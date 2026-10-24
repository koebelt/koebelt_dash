import 'dart:math' as math;
import 'dart:typed_data';

import '../link/protocol.dart';
import '../link/radio.dart';
import '../link/session.dart';
import '../scripts/script_hub.dart' show ScriptDrive;
import '../scripts/views.dart';
import '../video/video_hub.dart';
import '../video/video_rec.dart';
import 'alerts.dart';
import 'dash.dart' show RecEvent;
import 'model.dart';
import 'sequence.dart';
import 'telemetry.dart';

/// One connected device: its session and everything the app tracks about
/// it. [Dash] holds several; the screens show the focused one.
class DeviceLink {
  DeviceLink(this.info, this.session, this.tel);
  final DeviceInfo info;
  final DeviceSession session;
  Telemetry tel;
  final hist = History();

  String get id => info.id;
  DeviceKind get kind => info.kind;

  /// Stick axes (lx ly rx ry) sent in the control heartbeat. Only the focused
  /// device's move; the others stay centred, so they hold.
  final List<double> input = [0, 0, 0, 0];

  /// A Python script driving this device's sticks, or null.
  ScriptDrive? drive;

  /// Boxes a script draws over the camera (normalised x, y, w, h, label),
  /// and when: they fade a second after the last update.
  ({List<({double x, double y, double w, double h, String label})> boxes, DateTime at})? overlay;

  /// Pictures, charts and plots scripts show for this device, by name: Live
  /// widgets.
  final Map<String, ScriptView> views = {};
  List<double> jog = List.filled(6, 0);
  double speed = .5;

  // link health
  double linkTest = 0, linkRestored = 0;
  bool wasLost = false;
  final alerts = AlertMonitor();
  double alertAcc = 0;

  /// Seconds since the link was lost, 0 when healthy.
  double get linkLostFor {
    if (linkTest > 0) return 6 - linkTest;
    final slow = rates;
    final s = session.silence, limit = slow == null ? 1.0 : math.max(1.0, 3.0 / slow.tlmHz);
    return s > limit ? s : 0;
  }

  /// Rates for slow links (radios, Bluetooth serial modules); null for fast ones.
  ({int ctlHz, int tlmHz})? get rates => linkRatesFor(info);

  // what the device declared
  List<VideoStream> video = const [];

  /// Why this app version does not support the device's koebelt/link, or null.
  String? compatProblem;
  String? fwVersion;
  int seqCap = 0;

  SequenceRunner? runner;
  bool estopAck = false;

  /// Commanded bench throttle (0–1); the device reports only the output.
  double benchThrottle = 0;

  // parameters arriving in several messages
  bool paramWriting = false, paramsMore = false;
  List paramsAcc = [];

  final List<Msg> logs = [];

  // recording
  List<Map<String, dynamic>>? recFrames;
  List<RecEvent> recEvents = [];
  double recLast = -1;
  ({VideoRecorder rec, VideoFeed feed, VideoStream stream, void Function(Uint8List) tap})? vid;
}

/// Rates for slow links: radios follow their profile, third-party serial
/// modules (HM-10, HC-05…) run at 5 Hz because they sit on a 9600-baud UART.
/// Null for fast links.
({int ctlHz, int tlmHz})? linkRatesFor(DeviceInfo d) {
  if (d.transport == TransportKind.radio) {
    final r = radioModule(d.radio);
    return (ctlHz: r.ctlHz, tlmHz: r.tlmHz);
  }
  if (d.module != null) return (ctlHz: 5, tlmHz: 5);
  return null;
}
