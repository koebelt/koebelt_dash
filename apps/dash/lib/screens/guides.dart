import 'dart:math' as math;
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/dash.dart';
import '../link/discovery.dart';
import '../theme/tokens.dart';
import '../ui/components.dart';
import '../ui/icons.dart';
import '../ui/mark.dart';
import 'guides_data.dart';

final _kw = {
  'cpp': RegExp(r'^(void|auto|const|float|int|bool|if|return|include|true|false)$'),
  'python': RegExp(r'^(from|import|def|while|True|False|return|print|if)$'),
  'rust': RegExp(r'^(use|let|mut|loop|if|fn|Some|await|const)$'),
  'bash': RegExp(r'^(sudo|pip|cargo|cd|git|colcon|ros2|apt)$'),
};

/// Tiny highlighter matching the design: comments, strings, numbers, @decorators, keywords.
List<TextSpan> highlight(String code, String lang, TextStyle base) {
  if (lang == 'yaml') {
    final out = <TextSpan>[];
    for (final ln in code.split('\n')) {
      final m = RegExp(r'^(\s*)([a-z_]+)(:)(.*)$').firstMatch(ln);
      if (m != null) {
        out
          ..add(TextSpan(text: m[1]))
          ..add(
            TextSpan(
              text: m[2],
              style: base.copyWith(color: K.white, fontWeight: FontWeight.w600),
            ),
          )
          ..add(TextSpan(text: m[3]))
          ..addAll(highlight(m[4]!, 'bash', base));
      } else {
        out.addAll(highlight(ln, 'bash', base));
      }
      out.add(const TextSpan(text: '\n'));
    }
    return out;
  }
  final cm = lang == 'cpp' || lang == 'rust'
      ? r'//[^\n]*'
      : lang == 'json'
      ? r'(?!x)x'
      : r'#[^\n]*';
  final re = RegExp('($cm)|("[^"\\n]*")|(\\b\\d[\\d.]*(?:E\\d+)?\\b)|(@\\w+)|(\\b\\w+\\b)', multiLine: true);
  final out = <TextSpan>[];
  var last = 0;
  for (final m in re.allMatches(code)) {
    if (m.start > last) out.add(TextSpan(text: code.substring(last, m.start)));
    final s = m[0]!;
    Color? c;
    var bold = false;
    if (m[1] != null) {
      c = K.ink200;
    } else if (m[2] != null) {
      c = K.info;
    } else if (m[3] != null) {
      c = K.warning;
    } else if (m[4] != null) {
      c = K.lime500;
    } else if (_kw[lang]?.hasMatch(s) ?? false) {
      c = K.white;
      bold = true;
    }
    out.add(
      TextSpan(
        text: s,
        style: c == null ? null : base.copyWith(color: c, fontWeight: bold ? FontWeight.w600 : null),
      ),
    );
    last = m.end;
  }
  out.add(TextSpan(text: code.substring(last)));
  return out;
}

class CodeBlock extends StatefulWidget {
  const CodeBlock({super.key, required this.lang, required this.code, this.file});
  final String lang, code;
  final String? file;
  @override
  State<CodeBlock> createState() => _CodeBlockState();
}

class _CodeBlockState extends State<CodeBlock> {
  bool ok = false;
  @override
  Widget build(BuildContext context) {
    final base = KText.mono(12.5, w: FontWeight.w400, color: K.ink050, height: 1.65);
    return Container(
      decoration: BoxDecoration(
        color: K.surfaceDeep,
        border: Border.all(color: K.borderHairline),
        borderRadius: BorderRadius.circular(K.radiusCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 36,
            padding: const EdgeInsets.fromLTRB(14, 0, 8, 0),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: K.borderHairline)),
            ),
            child: Row(
              children: [
                Expanded(child: MonoLabel(widget.file ?? widget.lang, size: 10)),
                Pressable(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: widget.code));
                    setState(() => ok = true);
                    Timer(const Duration(milliseconds: 1400), () {
                      if (mounted) setState(() => ok = false);
                    });
                  },
                  builder: (_, h, _) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    child: Row(
                      children: [
                        if (ok) ...[const KIcon('check', size: 14, color: K.textAccent), const SizedBox(width: 6)],
                        Text(
                          ok ? 'COPIED' : 'COPY',
                          style: KText.mono(
                            11,
                            color: ok
                                ? K.textAccent
                                : h
                                ? K.textPrimary
                                : K.textMuted,
                            tracking: K.trLabel,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: SelectableText.rich(TextSpan(style: base, children: highlight(widget.code, widget.lang, base))),
          ),
        ],
      ),
    );
  }
}

class PlatformSeg extends StatelessWidget {
  const PlatformSeg({super.key, required this.ids, required this.value, required this.onChanged});
  final List<String> ids;
  final String value;
  final ValueChanged<String> onChanged;
  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 6,
    runSpacing: 6,
    children: [
      for (final p in platforms.where((p) => ids.contains(p.id)))
        Pressable(
          onTap: () => onChanged(p.id),
          builder: (_, h, _) {
            final on = p.id == value;
            return AnimatedContainer(
              duration: K.durFast,
              height: 32,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: on ? K.surfaceAccentSoft : Colors.transparent,
                border: Border.all(
                  color: on
                      ? K.accent
                      : h
                      ? K.borderStrong
                      : K.borderSubtle,
                ),
                borderRadius: BorderRadius.circular(K.radiusPill),
              ),
              child: Center(
                widthFactor: 1,
                child: Text(
                  p.name.toUpperCase(),
                  style: KText.mono(11, color: on ? K.textAccent : K.textSecondary, tracking: K.trLabel),
                ),
              ),
            );
          },
        ),
    ],
  );
}

/// Pairing code + listen for a device announcing it.
class PairPanel extends StatefulWidget {
  const PairPanel(this.d, {super.key, required this.go});
  final Dash d;
  final ValueChanged<String> go;
  @override
  State<PairPanel> createState() => _PairPanelState();
}

class _PairPanelState extends State<PairPanel> {
  String st = 'idle';
  String? pairedId, error;
  Timer? _timeout;

  @override
  void dispose() {
    if (st != 'idle') widget.d.stopScan();
    _timeout?.cancel();
    super.dispose();
  }

  void _listen() {
    setState(() => st = 'listen');
    widget.d.startScan();
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.d, code = d.currentPairCode;
    final Found? hit = d.found.values.where((f) => f.pair == code).firstOrNull;
    final paired = pairedId == null ? null : d.devices.where((x) => x.id == pairedId).firstOrNull;
    return Panel(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.end,
            spacing: 16,
            runSpacing: 16,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const MonoLabel('Your pairing code · valid 10 min'),
                  const SizedBox(height: 8),
                  SelectableText(
                    code,
                    style: KText.mono(36, w: FontWeight.w600, color: K.textAccent, tracking: .08),
                  ),
                ],
              ),
              if (paired != null) KBadge('${paired.name} paired') else if (st == 'idle') KButton('Start listening', size: KSize.sm, onPressed: _listen),
            ],
          ),
          if (paired == null && st == 'listen' && hit == null) ...[
            const SizedBox(height: 14),
            hairline,
            const SizedBox(height: 14),
            const Row(
              children: [
                MarkMotion(MarkLoop.searching, size: 36),
                SizedBox(width: 10),
                Expanded(child: MonoLabel('Listening on Wi-Fi and BLE · power on your device')),
              ],
            ),
          ],
          if (paired == null && hit != null) ...[
            const SizedBox(height: 14),
            hairline,
            const SizedBox(height: 14),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 12,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('${hit.name} found', style: KText.bodyMd),
                    const SizedBox(height: 6),
                    MonoLabel(
                      '${hit.kind[0].toUpperCase()}${hit.kind.substring(1)} · ${hit.lib ?? 'koebelt/link'} · ${hit.via} · ${hit.sensors.length} sensors',
                    ),
                  ],
                ),
                KButton(
                  'Add to devices',
                  size: KSize.sm,
                  onPressed: () async {
                    final e = await d.pair(hit);
                    setState(() {
                      error = e;
                      if (e == null) pairedId = hit.id;
                    });
                  },
                ),
              ],
            ),
          ],
          if (error != null) ...[const SizedBox(height: 14), KNotice(tone: Tone.negative, child: Text(error!))],
          if (paired != null) ...[
            const SizedBox(height: 14),
            hairline,
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                KButton(
                  d.links.containsKey(paired.id) ? 'Connected' : 'Connect now',
                  size: KSize.sm,
                  onPressed: d.links.containsKey(paired.id) || d.connecting != null
                      ? null
                      : () {
                          if (d.replay != null) d.closeReplay();
                          d.connect(paired.id);
                          widget.go('live');
                        },
                ),
                KButton('View devices', size: KSize.sm, variant: KButtonVariant.ghost, onPressed: () => widget.go('devices')),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class GuideView extends StatefulWidget {
  const GuideView(this.d, {super.key, required this.g, required this.w, required this.go, required this.back});
  final Dash d;
  final Guide g;
  final double w;
  final ValueChanged<String> go;
  final VoidCallback back;
  @override
  State<GuideView> createState() => _GuideViewState();
}

class _GuideViewState extends State<GuideView> {
  final _scroll = ScrollController();
  final _viewport = GlobalKey();
  late final _keys = List.generate(widget.g.steps.length, (_) => GlobalKey());
  int _active = 0;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_track);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  /// The step whose heading has scrolled past the top third of the view is "current".
  void _track() {
    final vp = _viewport.currentContext?.findRenderObject() as RenderBox?;
    if (vp == null) return;
    var active = 0;
    for (var i = 0; i < _keys.length; i++) {
      final box = _keys[i].currentContext?.findRenderObject() as RenderBox?;
      if (box == null) continue;
      final y = box.localToGlobal(Offset.zero, ancestor: vp).dy;
      if (y <= vp.size.height / 3) active = i;
    }
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 2) active = _keys.length - 1;
    if (active != _active) setState(() => _active = active);
  }

  void _jump(int i) {
    final c = _keys[i].currentContext;
    if (c != null) Scrollable.ensureVisible(c, duration: K.durBase, curve: K.easeStandard);
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.d, g = widget.g, w = widget.w, phone = w < 600, wide = w >= 1000;
    // `platforms: []` marks a guide about the app itself: no code, no platform switch.
    final appOnly = g.platforms?.isEmpty ?? false;
    final ids = appOnly ? [platforms.first.id] : g.platforms ?? platforms.map((p) => p.id).toList();
    var plat = d.platform;
    if (!ids.contains(plat)) plat = ids.first;
    final P = platforms.firstWhere((p) => p.id == plat);
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MonoLabel('${g.mins} min · ${appOnly ? 'In the app' : P.name}', color: K.textAccent),
        const SizedBox(height: 14),
        Text(g.title, style: phone ? KText.headingMd : KText.headingLg),
        const SizedBox(height: 14),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Text(g.sub, style: KText.bodyLg.copyWith(color: K.textSecondary)),
        ),
        if (!appOnly) const SizedBox(height: 14),
        if (!appOnly)
          Align(
            alignment: Alignment.centerLeft,
            child: PlatformSeg(
              ids: ids,
              value: plat,
              onChanged: (v) {
                d.platform = v;
                d.emit();
              },
            ),
          ),
        if (g.id == 'quickstart') ...[const SizedBox(height: 14), MonoLabel('${P.pkg} via ${P.install} · ${P.boards}', height: 1.7)],
        if (g.table != null) ...[SizedBox(height: phone ? 24 : 32), GuideTable(rows: g.table!)],
        for (var i = 0; i < g.steps.length; i++) ...[
          SizedBox(height: phone ? 24 : 32),
          Column(
            key: _keys[i],
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text((i + 1).toString().padLeft(2, '0'), style: KText.mono(13, color: K.textAccent)),
                  const SizedBox(width: 14),
                  Expanded(child: Text(g.steps[i].t, style: KText.headingSm)),
                ],
              ),
              const SizedBox(height: 14),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: Text(g.steps[i].p, style: KText.bodyMd.copyWith(color: K.textSecondary)),
              ),
              if (g.steps[i].bullets.isNotEmpty) ...[const SizedBox(height: 12), Bullets(items: g.steps[i].bullets)],
              if (g.steps[i].table != null) ...[const SizedBox(height: 14), GuideTable(rows: g.steps[i].table!)],
              if (g.steps[i].c[plat] != null) ...[
                const SizedBox(height: 14),
                CodeBlock(lang: g.steps[i].c[plat]![0], code: g.steps[i].c[plat]![1], file: g.steps[i].complete ? 'Complete program · ${P.name}' : null),
              ],
              if (g.steps[i].note != null) ...[
                const SizedBox(height: 14),
                KNotice(tone: g.steps[i].warn ? Tone.warning : Tone.info, child: Text(g.steps[i].note!)),
              ],
              if (g.steps[i].pair) ...[const SizedBox(height: 14), PairPanel(d, go: widget.go)],
            ],
          ),
        ],
        if (!appOnly) ...[
          const SizedBox(height: 32),
          hairline,
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              KButton(
                'API reference',
                size: KSize.sm,
                variant: KButtonVariant.secondary,
                iconRight: const KIcon('arrow-up-right', size: 14),
                onPressed: () => launchUrl(Uri.parse('$repoUrl/tree/main/${P.path}#readme')),
              ),
              KButton(
                'Example projects',
                size: KSize.sm,
                variant: KButtonVariant.ghost,
                iconRight: const KIcon('github', size: 14),
                onPressed: () => launchUrl(Uri.parse('$repoUrl/tree/main/${P.path}/examples')),
              ),
            ],
          ),
        ],
      ],
    );
    // Fixed bar: the way back is always one tap away.
    final bar = Container(
      height: 52,
      padding: EdgeInsets.symmetric(horizontal: phone ? 16 : 40),
      decoration: const BoxDecoration(
        color: K.surfacePage,
        border: Border(bottom: BorderSide(color: K.borderHairline)),
      ),
      child: Row(
        children: [
          Pressable(
            onTap: widget.back,
            builder: (_, h, _) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                KIcon('arrow-left', size: 14, color: h ? K.textPrimary : K.textMuted),
                const SizedBox(width: 8),
                Text(
                  'ALL GUIDES',
                  style: KText.mono(11, color: h ? K.textPrimary : K.textMuted, tracking: K.trLabel),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const MonoLabel('/', color: K.textFaint),
          const SizedBox(width: 12),
          Expanded(child: MonoLabel(g.title, color: K.textSecondary, maxLines: 1)),
          if (!wide && g.steps.length > 1) MonoLabel('Step ${_active + 1} of ${g.steps.length}'),
        ],
      ),
    );

    final body = SingleChildScrollView(
      key: _viewport,
      controller: _scroll,
      padding: phone ? const EdgeInsets.all(16) : const EdgeInsets.fromLTRB(40, 32, 40, 64),
      child: Align(
        alignment: Alignment.topLeft,
        child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 760), child: content),
      ),
    );

    if (!wide) {
      return Column(
        children: [
          bar,
          Expanded(child: body),
        ],
      );
    }

    // Wide: the steps index stays in place while the guide scrolls.
    final index = SizedBox(
      width: 240,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(40, 32, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const MonoLabel('Steps'),
            const SizedBox(height: 10),
            for (var i = 0; i < g.steps.length; i++)
              Pressable(
                onTap: () => _jump(i),
                builder: (_, h, _) {
                  final on = i == _active;
                  return Container(
                    padding: const EdgeInsets.fromLTRB(10, 6, 0, 6),
                    decoration: BoxDecoration(
                      border: Border(
                        left: BorderSide(color: on ? K.accent : K.borderHairline, width: on ? 2 : 1),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 3),
                          child: Text(
                            (i + 1).toString().padLeft(2, '0'),
                            style: KText.mono(11, color: on ? K.textAccent : K.textMuted, tracking: K.trLabel),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(g.steps[i].t, style: KText.bodySm.copyWith(color: on || h ? K.textPrimary : K.textSecondary)),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
    return Column(
      children: [
        bar,
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              index,
              const SizedBox(width: 8),
              Expanded(child: body),
            ],
          ),
        ),
      ],
    );
  }
}

class GuidesScreen extends StatefulWidget {
  const GuidesScreen(this.d, {super.key, required this.w, required this.go});
  final Dash d;
  final double w;
  final ValueChanged<String> go;

  /// A guide to open when the screen next shows (from a link elsewhere).
  static String? pending;
  @override
  State<GuidesScreen> createState() => _GuidesScreenState();
}

class _GuidesScreenState extends State<GuidesScreen> {
  String? open = GuidesScreen.pending;

  @override
  void initState() {
    super.initState();
    GuidesScreen.pending = null;
  }

  static const _platformNames = {'arduino': 'Arduino', 'python': 'Python', 'rust': 'Rust', 'ros2': 'ROS 2'};

  Widget _section(String title, String sub) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: KText.headingSm),
        const SizedBox(height: 6),
        Text(sub, style: KText.bodySm.copyWith(color: K.textMuted)),
      ],
    ),
  );

  Widget _row(Guide t) => Pressable(
    onTap: () => setState(() => open = t.id),
    builder: (_, h, _) => Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: K.borderHairline)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.title, style: KText.bodyLg.copyWith(color: h ? K.textAccent : K.textPrimary)),
                const SizedBox(height: 6),
                Text(t.sub, style: KText.bodySm.copyWith(color: K.textMuted)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          MonoLabel('${t.mins} min'),
          const SizedBox(width: 12),
          const KIcon('arrow-right', size: 16, color: K.textMuted),
        ],
      ),
    ),
  );

  Widget _deviceCard(Guide g) => Pressable(
    onTap: () => setState(() => open = g.id),
    builder: (_, h, _) => AnimatedContainer(
      duration: K.durFast,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: h ? K.surfaceHover : K.surfaceRaised,
        border: Border.all(color: h ? K.borderSubtle : K.borderHairline),
        borderRadius: BorderRadius.circular(K.radiusCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(g.title, style: KText.headingXs)),
              const KIcon('arrow-right', size: 16, color: K.textMuted),
            ],
          ),
          const SizedBox(height: 10),
          Text(g.sub, style: KText.bodySm.copyWith(color: K.textMuted)),
          const SizedBox(height: 12),
          MonoLabel(
            g.platforms?.isEmpty ?? false ? 'In the app' : [for (final p in g.platforms ?? const <String>[]) _platformNames[p] ?? p].join(' · '),
            color: K.textAccent,
          ),
        ],
      ),
    ),
  );
  @override
  Widget build(BuildContext context) {
    final d = widget.d, w = widget.w, phone = w < 600;
    final q = quickstart(d.currentPairCode);
    if (open != null) {
      final g = open == 'quickstart' ? q : guides.firstWhere((t) => t.id == open);
      return GuideView(d, g: g, w: w, go: widget.go, back: () => setState(() => open = null));
    }
    Widget card(Platform p) => Pressable(
      onTap: () {
        d.platform = p.id;
        setState(() => open = 'quickstart');
      },
      builder: (_, h, _) => AnimatedContainer(
        duration: K.durFast,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: h ? K.surfaceHover : K.surfaceRaised,
          border: Border.all(color: h ? K.borderSubtle : K.borderHairline),
          borderRadius: BorderRadius.circular(K.radiusCard),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(p.name, style: KText.headingXs)),
                const KIcon('arrow-right', size: 16, color: K.textMuted),
              ],
            ),
            const SizedBox(height: 12),
            Text(p.pkg, style: KText.mono(12, color: K.textAccent)),
            const SizedBox(height: 12),
            Text(p.fit, style: KText.bodySm.copyWith(color: K.textMuted)),
          ],
        ),
      ),
    );
    const flow = [
      ['Your device', 'Sensors, motors and koebelt/link on the board or companion computer.'],
      ['Link', 'Wi-Fi, BLE, USB serial or a radio, with a fallback link if one drops.'],
      ['koebelt/dash', 'Dashboards, control, tuning and recording, on phone, tablet or desktop.'],
    ];
    Widget flowCell(int i) => Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MonoLabel('${(i + 1).toString().padLeft(2, '0')} · ${flow[i][0]}', color: i == 1 ? K.textMuted : K.textPrimary),
          const SizedBox(height: 8),
          Text(flow[i][1], style: KText.bodySm.copyWith(color: K.textMuted)),
        ],
      ),
    );
    return SingleChildScrollView(
      padding: phone ? const EdgeInsets.all(16) : const EdgeInsets.fromLTRB(40, 32, 40, 64),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const MonoLabel('koebelt/link · library 1.0', color: K.textAccent),
            const SizedBox(height: 12),
            Text('Connect your hardware', style: phone ? KText.headingMd : KText.headingLg),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Text(
                'Your device runs a small library that streams sensors to this app and receives control input. Pick your platform to start.',
                style: KText.bodyLg.copyWith(color: K.textSecondary),
              ),
            ),
            SizedBox(height: phone ? 28 : 40),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: K.borderHairline),
                borderRadius: BorderRadius.circular(K.radiusCard),
              ),
              child: phone
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (var i = 0; i < 3; i++)
                          Container(
                            decoration: BoxDecoration(
                              border: i > 0 ? const Border(top: BorderSide(color: K.borderHairline)) : null,
                            ),
                            child: flowCell(i),
                          ),
                      ],
                    )
                  : IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (var i = 0; i < 3; i++)
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  border: i > 0 ? const Border(left: BorderSide(color: K.borderHairline)) : null,
                                ),
                                child: flowCell(i),
                              ),
                            ),
                        ],
                      ),
                    ),
            ),
            SizedBox(height: phone ? 28 : 40),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Expanded(child: Text('Quickstart', style: KText.headingSm)),
                MonoLabel('${q.mins} min · ${q.steps.length} steps'),
              ],
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (_, c) {
                final min = phone ? 160.0 : 220.0;
                final n = (c.maxWidth / min).floor().clamp(1, 4);
                final cw = (c.maxWidth - 12 * (n - 1)) / n;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [for (final p in platforms) SizedBox(width: cw, child: card(p))],
                );
              },
            ),
            SizedBox(height: phone ? 28 : 40),
            _section('Connections', 'How each link works, and what to do when a device does not show up.'),
            for (final t in guides.where((g) => g.section == 'connections')) _row(t),
            SizedBox(height: phone ? 28 : 40),
            _section('Device examples', 'A complete, commented program for each kind of device.'),
            LayoutBuilder(
              builder: (_, c) {
                final n = (c.maxWidth / (phone ? 160.0 : 240.0)).floor().clamp(1, 3);
                final cw = (c.maxWidth - 12 * (n - 1)) / n;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [for (final g in guides.where((g) => g.section == 'devices')) SizedBox(width: cw, child: _deviceCard(g))],
                );
              },
            ),
            SizedBox(height: phone ? 28 : 40),
            _section('Video, map and controllers', 'Show a camera, put the device on a map, drive with a gamepad.'),
            for (final t in guides.where((g) => g.section == 'features')) _row(t),
            SizedBox(height: phone ? 28 : 40),
            _section('Going further', 'Custom data, tuning, sequences and safety.'),
            for (final t in guides.where((g) => g.section == 'more')) _row(t),
          ],
        ),
      ),
    );
  }
}

class Bullets extends StatelessWidget {
  const Bullets({super.key, required this.items});
  final List<String> items;
  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 680),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final it in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(width: 6, height: 2, margin: const EdgeInsets.only(top: 11, right: 12), color: K.accent),
                Expanded(
                  child: Text(it, style: KText.bodyMd.copyWith(color: K.textSecondary)),
                ),
              ],
            ),
          ),
      ],
    ),
  );
}

/// Bordered table; the first row is the header. Text wraps; narrow screens scroll sideways.
class GuideTable extends StatelessWidget {
  const GuideTable({super.key, required this.rows});
  final List<List<String>> rows;

  static final _technical = RegExp(r'^[\w .:/·–\-+×%°()²]+$');

  @override
  Widget build(BuildContext context) {
    final n = rows.first.length;
    return LayoutBuilder(
      builder: (context, c) {
        final w = math.max(c.maxWidth, n * 150.0);
        return Container(
          decoration: BoxDecoration(
            border: Border.all(color: K.borderHairline),
            borderRadius: BorderRadius.circular(K.radiusCard),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: w - 2,
              child: Table(
                columnWidths: {for (var i = 0; i < n; i++) i: FlexColumnWidth(i == 0 ? .8 : 1)},
                children: [
                  for (var r = 0; r < rows.length; r++)
                    TableRow(
                      decoration: BoxDecoration(
                        color: r == 0 ? K.surfaceSunken : null,
                        border: r == rows.length - 1 ? null : const Border(bottom: BorderSide(color: K.borderHairline)),
                      ),
                      children: [
                        for (var i = 0; i < n; i++)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                            child: r == 0
                                ? MonoLabel(rows[r][i], height: 1.4)
                                : SelectableText(
                                    rows[r][i],
                                    style: i > 0 && rows[r][i].length < 28 && _technical.hasMatch(rows[r][i]) && rows[r][i].contains(RegExp(r'\d'))
                                        ? KText.mono(12, w: FontWeight.w400, color: K.textSecondary, height: 1.5)
                                        : KText.bodySm.copyWith(color: i == 0 ? K.textPrimary : K.textSecondary),
                                  ),
                          ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
