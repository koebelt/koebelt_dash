// The editor's completion popup and signature hint. Pictures with CAPTURE_DIR=/tmp/x.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:koebelt_dash/screens/code_editor.dart';
import 'package:koebelt_dash/scripts/completion.dart';

void main() {
  final shots = Platform.environment['CAPTURE_DIR'];
  const head = 'from koebelt_dash_scripts import connect, every\nrover = connect()\n\nfor _ in every(0.05):\n    ';

  testWidgets('a popup at the cursor: arrows, Enter, Esc; then the call’s parameters', (tester) async {
    await tester.runAsync(() async {
      for (final fam in ['Archivo', 'JetBrainsMono']) {
        final l = FontLoader(fam);
        for (final w in [400, 500, 600, 700]) {
          l.addFont(rootBundle.load('assets/fonts/$fam-$w.ttf'));
        }
        await l.load();
      }
    });
    tester.view.physicalSize = const Size(900, 520);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final c = PythonController(text: head);
    final key = GlobalKey<CodeEditorState>(), shotKey = GlobalKey();
    const ctx = CompletionContext(kind: 'rover', sticks: ['throttle', 'steer'], tlm: ['pos', 'battery']);
    await tester.pumpWidget(
      RepaintBoundary(
        key: shotKey,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          home: Scaffold(body: CodeEditor(key: key, controller: c, context: () => ctx)),
        ),
      ),
    );
    Future<void> type(String s) async {
      c.value = TextEditingValue(text: c.text + s, selection: TextSelection.collapsed(offset: c.text.length + s.length));
      await tester.pump();
    }

    Future<void> shot(String name) async {
      if (shots == null) return;
      await tester.runAsync(() async {
        final b = shotKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final img = await b.toImage();
        final png = await img.toByteData(format: ui.ImageByteFormat.png);
        await File('$shots/$name.png').writeAsBytes(png!.buffer.asUint8List());
      });
    }

    await tester.tap(find.byType(TextField));
    await tester.pump();
    await type('rover.s');
    expect(find.text('sticks()'), findsOneWidget, reason: 'the popup');
    expect(find.text('setting()'), findsOneWidget);
    await shot('completion_popup');

    // Down to the second item, Enter: it is inserted with the cursor inside.
    final second = key.currentState!.completions.items[1];
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(c.text, endsWith('rover.${second.insert}'));
    if (second.cursorBack > 0) expect(c.selection.start, c.text.length - second.cursorBack);

    // Esc closes it until the next edit.
    c.text = head;
    await type('rover.tlm.ba');
    expect(find.text('battery'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(find.text('battery'), findsNothing);

    // In a call: the parameters, the current one highlighted.
    c.text = head;
    await type('rover.goto(4, ');
    expect(find.textContaining('metres north'), findsOneWidget);
    await shot('completion_signature');
    // And the device's sticks in sticks(.
    c.text = head;
    await type('rover.sticks(');
    expect(find.text('throttle='), findsOneWidget);
    expect(find.text('steer='), findsOneWidget);
    await shot('completion_sticks');
  });
}
