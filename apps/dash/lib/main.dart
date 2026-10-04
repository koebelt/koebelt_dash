import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'core/dash.dart';
import 'theme/tokens.dart';
import 'viz/map_view.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
  await initMapCache();
  final dash = Dash();
  runApp(KoebeltDash(dash: dash));
  await dash.init();
}

class KoebeltDash extends StatelessWidget {
  const KoebeltDash({super.key, required this.dash});
  final Dash dash;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'koebelt dash',
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
      home: Scaffold(body: DashApp(dash: dash)),
    );
  }
}
