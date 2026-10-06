import 'dart:io';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Desktop: native save dialog. Mobile: share sheet (Files, AirDrop, mail…).
/// Returns where it went, or null when cancelled.
Future<String?> saveBytes(String name, Uint8List bytes, String mime) async {
  if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
    final ext = name.split('.').last;
    final loc = await getSaveLocation(
      suggestedName: name,
      acceptedTypeGroups: [
        XTypeGroup(label: ext.toUpperCase(), extensions: [ext], mimeTypes: [mime]),
      ],
    );
    if (loc == null) return null;
    await File(loc.path).writeAsBytes(bytes);
    return loc.path;
  }
  final dir = await getTemporaryDirectory();
  final f = File('${dir.path}/$name');
  await f.writeAsBytes(bytes);
  final r = await SharePlus.instance.share(
    ShareParams(
      files: [XFile(f.path, mimeType: mime)],
      subject: name,
    ),
  );
  return r.status == ShareResultStatus.dismissed ? null : 'Shared $name';
}

/// Native open dialog. Desktop filters by [extensions]; phones list every
/// file (their pickers know types by UTI / MIME, which log formats lack).
/// Returns the file name and its bytes, or null when cancelled.
Future<(String, Uint8List)?> openBytes(String label, List<String> extensions) async {
  final desktop = Platform.isMacOS || Platform.isWindows || Platform.isLinux;
  final f = await openFile(
    acceptedTypeGroups: [desktop ? XTypeGroup(label: label, extensions: extensions) : const XTypeGroup(label: 'Files')],
  );
  if (f == null) return null;
  return (f.name, await f.readAsBytes());
}
