import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:koebelt_dash/app.dart';
import 'package:koebelt_dash/core/dash.dart';
import 'package:koebelt_dash/scripts/library.dart';
import 'package:koebelt_dash/screens/scripts.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _loadFonts() async {
  for (final fam in ['Archivo', 'JetBrainsMono']) {
    final l = FontLoader(fam);
    for (final w in [400, 500, 600, 700]) {
      l.addFont(rootBundle.load('assets/fonts/$fam-$w.ttf'));
    }
    await l.load();
  }
}

void main() {
  for (final phone in [false, true]) {
    testWidgets('clicking an example copies it into the library and opens it (${phone ? 'phone' : 'desktop'})', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.runAsync(_loadFonts);
      final d = Dash();
      late ScriptLibrary lib;
      await tester.runAsync(() async {
        await d.init();
        lib = ScriptLibrary(Directory('${(await Directory.systemTemp.createTemp('kdash-ex')).path}/koebelt/dash-scripts'));
      });
      final size = phone ? const Size(440, 956) : const Size(1440, 900);
      tester.view.physicalSize = size * 2;
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScriptsLibraryScope(library: lib, child: DashApp(dash: d, initial: 'scripts')),
          ),
        ),
      );
      Future<void> settle() async {
        for (var i = 0; i < 10; i++) {
          await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 40)));
          await tester.pump(const Duration(milliseconds: 40));
        }
      }

      await settle();
      final tag = find.text('DRIVE SQUARE');
      expect(tag, findsOneWidget);
      await tester.ensureVisible(tag);
      await tester.pump();
      // On the real clock: the handler reads an asset and writes files.
      await tester.runAsync(() async {
        await tester.tap(tag);
        await Future<void>.delayed(const Duration(seconds: 1));
      });
      await settle();
      final files = await tester.runAsync(lib.list);
      expect(files!.map((f) => f.label), ['drive_square.py']);
      if (!phone) {
        final editor = tester.widgetList<EditableText>(find.byType(EditableText)).map((e) => e.controller.text);
        expect(editor.any((t) => t.contains('A rover drives a square')), isTrue, reason: 'the example is open in the editor');
      } else {
        expect(find.textContaining('A rover drives a square'), findsWidgets, reason: 'the example\'s page is open');
      }
      // Again: the copy opens, no second one.
      if (!phone) {
        await tester.runAsync(() async {
          await tester.tap(find.text('DRIVE SQUARE'));
          await Future<void>.delayed(const Duration(seconds: 1));
        });
        await settle();
        expect((await tester.runAsync(lib.list))!.map((f) => f.label), ['drive_square.py']);
      }
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 10));
    });
  }
}
