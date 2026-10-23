import 'dart:convert';

import 'package:flutter/services.dart';

import 'model.dart';

/// Which koebelt/link libraries an app version works with, from compat.json
/// (bundled with the app, and published with each release so an installed app
/// can check a release before installing it):
///
///   protocol  the protocol version the app speaks; a device announcing a
///             newer one needs a newer app
///   minLib    the oldest library version still supported, per library
///             (the family in a device's `lib`, "arduino/1.4.2")
///
/// Raise a minimum only when the app drops support for older devices, and
/// say so in the release notes; tools/compat/run.sh tests every published
/// library version from these minimums up.
class Compat {
  const Compat({required this.protocol, required this.minLib});
  final int protocol;
  final Map<String, String> minLib;

  /// What 1.0.0 and 1.1.0 supported, which published no compat.json.
  static const legacy = Compat(protocol: 1, minLib: {});

  Compat copyWith({int? protocol, Map<String, String>? minLib}) => Compat(protocol: protocol ?? this.protocol, minLib: minLib ?? this.minLib);

  factory Compat.fromJson(Map j) =>
      Compat(protocol: (j['protocol'] as num?)?.toInt() ?? 1, minLib: {for (final e in ((j['minLib'] as Map?) ?? const {}).entries) '${e.key}': '${e.value}'});

  factory Compat.parse(String json) => Compat.fromJson(jsonDecode(json) as Map);

  /// This app's own, from the bundled compat.json.
  static Future<Compat> bundled() async {
    try {
      return Compat.parse(await rootBundle.loadString('compat.json'));
    } catch (_) {
      return legacy;
    }
  }

  /// Why a device running [lib] at protocol [protocolVersion] does not work
  /// with this version, or null when it does (or when it runs no koebelt/link).
  String? problem(String? lib, int? protocolVersion) {
    if (protocolVersion != null && protocolVersion > protocol) {
      return 'it speaks protocol $protocolVersion, newer than this version of koebelt dash (protocol $protocol)';
    }
    final l = parseLib(lib);
    final min = l == null ? null : minLib[l.family];
    if (l != null && min != null && compareVersions(l.version, min) < 0) {
      return 'it runs koebelt/link $lib, and this version needs ${l.family}/$min or later';
    }
    return null;
  }

  /// The paired devices this version would not work with, with why.
  List<({DeviceInfo device, String why})> incompatible(Iterable<DeviceInfo> devices) => [
    for (final d in devices)
      if (problem(d.lib, d.protocol) case final why?) (device: d, why: why),
  ];
}

/// "arduino/1.4.2" → (family: arduino, version: 1.4.2).
({String family, String version})? parseLib(String? lib) {
  final i = lib?.indexOf('/') ?? -1;
  if (lib == null || i <= 0 || i == lib.length - 1) return null;
  return (family: lib.substring(0, i), version: lib.substring(i + 1));
}

/// Compares dotted versions numerically: 1.10.0 > 1.9.2.
int compareVersions(String a, String b) {
  // 1.3.0-beta.1: the numbers, then the pre-release, which comes before the
  // release itself (beta.1 < beta.2 < rc.1 < none).
  final (ca, pa) = _split(a);
  final (cb, pb) = _split(b);
  List<int> parts(String v) => [for (final p in v.split('.')) int.tryParse(p) ?? 0];
  final x = parts(ca), y = parts(cb);
  for (var i = 0; i < x.length || i < y.length; i++) {
    final d = (i < x.length ? x[i] : 0) - (i < y.length ? y[i] : 0);
    if (d != 0) return d.sign;
  }
  if (pa == pb) return 0;
  if (pa == null) return 1;
  if (pb == null) return -1;
  final xs = pa.split('.'), ys = pb.split('.');
  for (var i = 0; i < xs.length && i < ys.length; i++) {
    final n = int.tryParse(xs[i]), m = int.tryParse(ys[i]);
    final d = n != null && m != null ? n - m : xs[i].compareTo(ys[i]);
    if (d != 0) return d.sign;
  }
  return (xs.length - ys.length).sign;
}

(String, String?) _split(String v) {
  final i = v.indexOf('-');
  return i < 0 ? (v, null) : (v.substring(0, i), v.substring(i + 1));
}

/// Whether a version is a beta or release candidate (1.3.0-beta.1).
bool isPrerelease(String v) => v.contains('-');

/// The same version as Python packages write it: 1.3.0-beta.1 → 1.3.0b1, rc → rc.
String pep440(String v) {
  final m = RegExp(r'^(\d+\.\d+\.\d+)(?:-(alpha|beta|rc)\.?(\d+))?$').firstMatch(v);
  if (m == null || m[2] == null) return v;
  return '${m[1]}${const {'alpha': 'a', 'beta': 'b', 'rc': 'rc'}[m[2]]}${m[3]}';
}
