import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'core/dash.dart';
import 'core/macos_migrate.dart';
import 'screens/assistant_ui.dart';
import 'scripts/script_hub.dart';
import 'theme/tokens.dart';
import 'ui/mark.dart';
import 'viz/map_view.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
  await migrateFromSandbox();
  await initMapCache();
  final dash = Dash();
  // The boundary lets an assistant take a screenshot (MCP).
  runApp(RepaintBoundary(key: dash.mcp.screenKey, child: KoebeltDash(dash: dash)));
  await dash.init();
  // The script API, for Python scripts on this computer.
  if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
    await dash.scripts.start(discovery: ScriptHub.defaultDiscovery());
  }
  // AI assistants from the network (phones and tablets: only from there).
  await applyMcpListening(dash);
}

class KoebeltDash extends StatelessWidget {
  const KoebeltDash({super.key, required this.dash});
  final Dash dash;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'koebelt/dash',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: K.surfacePage,
        canvasColor: K.surfacePage,
        colorScheme: const ColorScheme.dark(primary: K.accent, onPrimary: K.textOnAccent, surface: K.surfacePage, onSurface: K.textPrimary),
        textSelectionTheme: const TextSelectionThemeData(cursorColor: K.accent, selectionColor: K.limeA32, selectionHandleColor: K.accent),
        tooltipTheme: TooltipThemeData(
          decoration: BoxDecoration(
            color: K.surfaceRaised,
            border: Border.all(color: K.borderSubtle),
            borderRadius: BorderRadius.circular(K.radiusControl),
          ),
          textStyle: KText.label(color: K.textPrimary),
        ),
        splashFactory: NoSplash.splashFactory,
        highlightColor: Colors.transparent,
      ),
      home: Scaffold(
        body: BootSplash(child: DashApp(dash: dash)),
      ),
    );
  }
}
