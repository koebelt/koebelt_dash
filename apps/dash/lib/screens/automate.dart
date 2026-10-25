import 'package:flutter/material.dart';

import '../core/dash.dart';
import '../scripts/library.dart';
import '../scripts/script_hub.dart' show ScriptHub;
import '../theme/tokens.dart';
import '../ui/components.dart';
import '../ui/icons.dart';
import 'guides.dart';
import 'scripts.dart' show ScriptsLibraryScope;

/// Automate: the two ways to automate a device, side by side, each a door to
/// its screen (Sequences, Scripts).
class AutomateHome extends StatefulWidget {
  const AutomateHome(this.d, {super.key, required this.w, required this.go});
  final Dash d;
  final double w;
  final ValueChanged<String> go;
  @override
  State<AutomateHome> createState() => _AutomateHomeState();
}

class _AutomateHomeState extends State<AutomateHome> {
  List<String>? _scripts;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final l = context.getInheritedWidgetOfExactType<ScriptsLibraryScope>()?.library ?? ScriptLibrary(await ScriptLibrary.defaultDir());
      final files = await l.list();
      if (mounted) setState(() => _scripts = [for (final f in files) f.name]);
    } catch (_) {
      if (mounted) setState(() => _scripts = const []);
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.d, phone = widget.w < 600, wide = widget.w >= 900;
    final dev = d.focus;
    final seqs = dev == null ? const <String>[] : [for (final q in d.sequencesFor(dev.id)) q.name];
    final scripts = _scripts;
    String count(int n, String one, String many) => '$n ${n == 1 ? one : many}';

    final sequences = _Door(
      icon: 'list-checks',
      title: 'Sequences',
      blurb: 'Steps in order, no code: take off, fly to, wait, land; drive to; move to a pose.',
      points: const ['No code: build it in the app', 'Runs on the device when it can store it', 'Keeps going if the link drops'],
      footer: dev == null ? 'Connect a device to build its sequences' : '${count(seqs.length, 'sequence', 'sequences')} for ${dev.info.name}',
      names: seqs,
      onOpen: () => widget.go('program'),
      fill: wide,
      compact: phone,
    );
    final scriptsDoor = _Door(
      icon: 'code',
      title: 'Scripts',
      blurb: 'Python that reads the telemetry and the camera, decides, and drives the device.',
      points: [
        'Logic, sensors, the camera',
        'Any package: OpenCV, PyTorch, YOLO',
        ScriptHub.canRunHere ? 'Triggers: buttons, keys, conditions, timers' : 'Runs on a script host: a computer on your network',
      ],
      footer: scripts == null ? '…' : count(scripts.length, 'script', 'scripts'),
      names: scripts ?? const [],
      onOpen: () => widget.go('scripts'),
      fill: wide,
      compact: phone,
    );
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(phone ? 16 : 32, phone ? 20 : 32, phone ? 16 : 32, 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1080),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PageHead(phone: phone, eyebrow: 'Two ways to automate', title: 'Automate'),
              SizedBox(height: phone ? 20 : 28),
              if (wide)
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: sequences),
                      const SizedBox(width: 16),
                      Expanded(child: scriptsDoor),
                    ],
                  ),
                )
              else ...[
                sequences,
                const SizedBox(height: 12),
                scriptsDoor,
              ],
              const SizedBox(height: 16),
              _together(),
            ],
          ),
        ),
      ),
    );
  }

  /// How they combine, and the guide that compares them.
  Widget _together() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    decoration: BoxDecoration(
      border: Border.all(color: K.borderHairline),
      borderRadius: BorderRadius.circular(K.radiusCard),
    ),
    child: Wrap(
      spacing: 16,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.center,
      alignment: WrapAlignment.spaceBetween,
      children: [
        Text.rich(
          TextSpan(
            children: [
              const TextSpan(text: 'Together: a script can start a sequence, '),
              TextSpan(
                text: 'dev.run_sequence("…")',
                style: KText.mono(12.5, color: K.textPrimary, w: FontWeight.w400),
              ),
              const TextSpan(text: ', and decide when.'),
            ],
          ),
          style: KText.bodySm.copyWith(color: K.textSecondary),
        ),
        Pressable(
          onTap: () {
            GuidesScreen.pending = 'sequence-or-script';
            widget.go('guides');
          },
          builder: (_, h, _) => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Sequence or script?', style: KText.bodySm.copyWith(color: h ? K.accentHover : K.textAccent)),
              const SizedBox(width: 4),
              KIcon('arrow-right', size: 14, color: h ? K.accentHover : K.textAccent),
            ],
          ),
        ),
      ],
    ),
  );
}

/// One way to automate: what it is, what it does best, what you have.
class _Door extends StatelessWidget {
  const _Door({
    required this.icon,
    required this.title,
    required this.blurb,
    required this.points,
    required this.footer,
    required this.names,
    required this.onOpen,
    this.fill = false,
    this.compact = false,
  });

  /// Phones: the icon beside the title, so both doors fit higher up.
  final bool compact;
  final String icon, title, blurb, footer;

  /// Side by side, in a row as tall as the taller one: the footer goes to the
  /// bottom.
  final bool fill;
  final List<String> points, names;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) => Pressable(
    onTap: onOpen,
    builder: (_, h, _) => AnimatedContainer(
      duration: K.durFast,
      padding: EdgeInsets.all(compact ? 18 : 24),
      decoration: BoxDecoration(
        color: h ? K.surfaceHover : K.surfaceRaised,
        border: Border.all(color: h ? K.accent : K.borderSubtle),
        borderRadius: BorderRadius.circular(K.radiusCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: compact ? 32 : 40,
                height: compact ? 32 : 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: K.limeA16, borderRadius: BorderRadius.circular(K.radiusControl)),
                child: KIcon(icon, size: compact ? 16 : 20, color: K.accent),
              ),
              if (compact) ...[const SizedBox(width: 12), Text(title, style: KText.headingXs)],
              const Spacer(),
              Text('OPEN', style: KText.label(size: 11, color: h ? K.textAccent : K.textMuted)),
              const SizedBox(width: 6),
              KIcon('arrow-right', size: 16, color: h ? K.accent : K.textMuted),
            ],
          ),
          if (!compact) ...[const SizedBox(height: 18), Text(title, style: KText.headingSm)],
          SizedBox(height: compact ? 12 : 8),
          Text(blurb, style: KText.bodySm.copyWith(color: K.textSecondary)),
          const SizedBox(height: 16),
          for (final p in points)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 7),
                    child: Container(width: 6, height: 6, color: K.accent),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(p, style: KText.bodySm.copyWith(color: K.textSecondary)),
                  ),
                ],
              ),
            ),
          if (fill) const Spacer(),
          const SizedBox(height: 12),
          Container(height: 1, color: K.borderHairline),
          const SizedBox(height: 14),
          MonoLabel(footer),
          if (names.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              names.take(4).join(' · ') + (names.length > 4 ? ' · …' : ''),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: KText.bodySm.copyWith(fontSize: 13, color: K.textMuted),
            ),
          ],
        ],
      ),
    ),
  );
}

/// On phones and tablets, above Sequences and Scripts: back to Automate, and
/// the other one a tap away.
class AutomateBar extends StatelessWidget {
  const AutomateBar({super.key, required this.screen, required this.phone, required this.go});
  final String screen;
  final bool phone;
  final ValueChanged<String> go;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(phone ? 8 : 24, 10, phone ? 16 : 32, 0),
    child: Row(
      children: [
        Pressable(
          onTap: () => go('automate'),
          builder: (_, h, _) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                KIcon('arrow-left', size: 16, color: h ? K.textPrimary : K.textMuted),
                const SizedBox(width: 6),
                Text('AUTOMATE', style: KText.label(size: 11, color: h ? K.textPrimary : K.textMuted)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: KTabs(
            items: const ['Sequences', 'Scripts'],
            value: screen == 'scripts' ? 'Scripts' : 'Sequences',
            onChanged: (v) => go(v == 'Scripts' ? 'scripts' : 'program'),
          ),
        ),
      ],
    ),
  );
}
