import 'dart:io';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/dash.dart';
import '../core/gamepad.dart';
import '../core/compat.dart' show fromPep440;
import '../core/model.dart';
import '../scripts/hosts.dart';
import '../scripts/library.dart';
import '../scripts/requirements.dart';
import '../scripts/script_hub.dart';
import '../scripts/script_runner.dart';
import '../scripts/triggers.dart';
import '../theme/tokens.dart';
import '../ui/components.dart';
import '../ui/icons.dart';
import 'script_dialogs.dart';

/// The run side of a script's page: where and with what it runs, Run/Stop,
/// its state, settings, triggers and limits.
class ScriptRunPanel extends StatelessWidget {
  const ScriptRunPanel({super.key, required this.d, required this.script, required this.scriptsDir, required this.onRun, required this.phone, this.requires = const ScriptRequirements()});

  /// What the script needs, from its code as it is in the editor.
  final ScriptRequirements requires;
  final Dash d;
  final ScriptFile script;
  final Directory scriptsDir;
  final VoidCallback onRun;
  final bool phone;

  ScriptHub get hub => d.scripts;

  @override
  Widget build(BuildContext context) {
    final cfg = hub.configFor(script.path);
    final run = hub.runs.where((r) => r.file.path == script.path).lastOrNull;
    final conn = run == null ? null : hub.connOf(run);
    final running = run?.state == ScriptState.running;
    final kind = conn?.device == null ? d.focus?.kind : d.links[conn!.device]?.kind;
    final local = hub.hostFor(cfg) == null && ScriptHub.canRunHere;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _status(context, run, conn),
        const SizedBox(height: 16),
        _kv('Device', _deviceChoice(cfg)),
        if (!requires.isEmpty) _kv('Needs', Text(requires.describe(), style: KText.mono(12, color: K.textSecondary))),
        _kv('Runs on', _hostChoice(context, cfg)),
        if (local) _kv('Python', _pythonChoice(context, cfg)),
        const SizedBox(height: 14),
        _runButtons(context, cfg, run, running),
        if (local && hub.setupResult != null) ...[const SizedBox(height: 12), _setupResult(hub.setupResult!)],
        if (local) ..._pythonSetup(context, cfg),
        if (!ScriptHub.canRunHere && hub.hosts.isEmpty) ...[
          const SizedBox(height: 12),
          KNotice(
            tone: Tone.info,
            title: 'Scripts run on a computer',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('This device sends them to a script host: a computer on the same network running koebelt-dash-scripts, which can use any Python package (OpenCV, PyTorch…).'),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: KButton('Add a script host', size: KSize.sm, onPressed: () => showAddHostDialog(context, d)),
                ),
              ],
            ),
          ),
        ],
        if (conn != null && conn.settings.isNotEmpty) ...[const SizedBox(height: 28), _settings(conn)],
        const SizedBox(height: 28),
        _triggers(context, cfg, conn, kind),
        const SizedBox(height: 28),
        _limits(context, cfg, kind),
      ],
    );
  }

  Widget _kv(String k, Widget v) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        SizedBox(width: 72, child: Text(k, style: KText.bodySm.copyWith(color: K.textMuted))),
        Expanded(child: v),
      ],
    ),
  );

  Widget _status(BuildContext context, ScriptRun? run, ScriptConn? conn) {
    String two(int n) => n.toString().padLeft(2, '0');
    final Widget head;
    if (run == null) {
      head = Text('NOT RUNNING', style: KText.labelMd(color: K.textMuted));
    } else if (run.state == ScriptState.running) {
      final s = DateTime.now().difference(run.startedAt).inSeconds;
      head = Row(
        children: [
          const PulseDot(color: K.positive),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'RUNNING ${two(s ~/ 60)}:${two(s % 60)}${run is RemoteRun ? ' · ${run.where}' : ''}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: KText.labelMd(color: K.positive),
            ),
          ),
          if (conn?.hz != null) Text('${conn!.hz!.toStringAsFixed(1)} Hz', style: KText.mono(12, color: K.textSecondary)),
        ],
      );
    } else {
      final failed = run.state == ScriptState.failed;
      head = Text(failed ? 'ENDED WITH AN ERROR' : 'ENDED', style: KText.labelMd(color: failed ? K.negative : K.textMuted));
    }
    final link = conn?.drive?.link;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        head,
        if (run != null && run.state == ScriptState.running && conn == null) ...[
          const SizedBox(height: 8),
          Text('Waiting for the script to connect (connect() in the script)…', style: KText.bodySm.copyWith(color: K.textMuted)),
        ],
        if (conn?.drive?.paused == true && link != null) ...[
          const SizedBox(height: 12),
          KNotice(
            tone: Tone.warning,
            title: 'You have the sticks',
            child: Row(
              children: [
                const Expanded(child: Text('You moved the sticks, so the script’s are ignored.')),
                KButton('Resume', size: KSize.sm, onPressed: () => hub.resume(link)),
              ],
            ),
          ),
        ],
        if (conn?.blocked != null) ...[
          const SizedBox(height: 12),
          KNotice(
            tone: Tone.negative,
            title: 'The script lost the sticks',
            child: Row(
              children: [
                Expanded(child: Text(conn!.blocked!)),
                KButton('Resume', size: KSize.sm, onPressed: () => hub.unblock(conn)),
              ],
            ),
          ),
        ],
      ],
    );
  }

  /// The device the script would run on now, and what it lacks for it.
  ({String? name, String? why}) _target(ScriptConfig cfg) {
    final l = (cfg.device == null ? null : d.links.values.where((x) => x.info.name == cfg.device).firstOrNull) ?? d.focus;
    return (name: l?.info.name, why: l == null ? null : requires.whyNot(l.info, l));
  }

  Widget _deviceChoice(ScriptConfig cfg) {
    final links = d.links.values.toList();
    final names = [for (final l in links) l.info.name];
    final value = cfg.device != null && names.contains(cfg.device) ? cfg.device : null;
    String fit(dynamic l) => requires.isEmpty || l == null || requires.missing(l.info, l).isEmpty ? '' : ' · does not fit';
    return _Dropdown<String?>(
      value: value,
      items: {null: 'Selected in dash${d.focus == null ? '' : ' (${d.focus!.info.name}${fit(d.focus)})'}', for (final l in links) l.info.name: '${l.info.name}${fit(l)}'},
      onChanged: (v) {
        cfg.device = v;
        hub.saveConfigs();
        d.emit();
      },
    );
  }

  Widget _hostChoice(BuildContext context, ScriptConfig cfg) {
    const add = '+';
    final current = hub.hostFor(cfg);
    return _Dropdown<String?>(
      value: current?.key,
      items: {
        if (ScriptHub.canRunHere) null: 'This computer',
        for (final h in hub.hosts) h.key: h.name,
        add: 'Add a script host…',
      },
      onChanged: (v) async {
        if (v == add) {
          final h = await showAddHostDialog(context, d);
          if (h == null) return;
          v = h.key;
        }
        cfg.host = v;
        hub.saveConfigs();
        d.emit();
      },
    );
  }

  Widget _pythonChoice(BuildContext context, ScriptConfig cfg) {
    final ps = hub.pythons;
    if (ps == null || hub.findingPythons) return Text('Looking for Python…', style: KText.mono(12, color: K.textMuted));
    if (ps.isEmpty) return Text('None found', style: KText.mono(12, color: K.negative));
    final current = hub.pythonFor(cfg);
    final home = Platform.environment['HOME'] ?? '';
    String short(String p) => home.isNotEmpty && p.startsWith(home) ? '~${p.substring(home.length)}' : p;
    return _Dropdown<String?>(
      value: ps.any((p) => p.path == current) ? current : null,
      items: {
        for (final p in ps) p.path: '${p.version} · ${short(p.path)}${p.hasPackage ? ' · lib ${fromPep440(p.packageVersion ?? '')}' : ' · no package'}',
        if (current != null && !ps.any((p) => p.path == current)) null: short(current),
      },
      onChanged: (v) {
        cfg.python = v;
        hub.saveConfigs();
        d.emit();
        // It may have changed since dash looked at it.
        if (v != null) hub.recheckPython(v);
      },
    );
  }

  List<Widget> _pythonSetup(BuildContext context, ScriptConfig cfg) {
    final ps = hub.pythons;
    if (ps == null) return const [];
    if (ps.isEmpty) {
      return [
        const SizedBox(height: 12),
        KNotice(
          tone: Tone.warning,
          title: 'Python 3 is needed',
          child: Row(
            children: [
              const Expanded(child: Text('Install it from python.org, then come back here.')),
              KButton('python.org', size: KSize.sm, variant: KButtonVariant.secondary, onPressed: () => launchUrl(Uri.parse('https://www.python.org/downloads/'))),
            ],
          ),
        ),
      ];
    }
    final chosen = hub.pythonFor(cfg), env = hub.envOf(chosen);
    if (env != null && env.hasPackage && !hub.settingUp && hub.packageOutdated(chosen)) {
      return [
        const SizedBox(height: 12),
        KNotice(
          tone: Tone.info,
          title: 'koebelt-dash-scripts ${fromPep440(env.packageVersion!)} → ${hub.latestPackage}',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('A newer version of the library scripts use is out, for this version of koebelt dash.'),
              if (hub.setupLog.isNotEmpty) ...[const SizedBox(height: 8), Text(hub.setupLog.last, style: KText.mono(11, color: K.textMuted))],
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: KButton('Update', size: KSize.sm, onPressed: () => hub.installInto(chosen!, upgrade: true)),
              ),
            ],
          ),
        ),
      ];
    }
    if (env != null && env.hasPackage && !hub.settingUp) return const [];
    if (chosen != null && !hub.settingUp) {
      return [
        const SizedBox(height: 12),
        KNotice(
          tone: Tone.warning,
          title: env == null ? 'This Python does not answer' : 'koebelt-dash-scripts is not in this Python',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                env == null
                    ? 'dash could not run $chosen. Choose another, or create a scripts environment.'
                    : 'Install it here (pip install koebelt-dash-scripts), or let dash create a scripts environment in the scripts folder.',
              ),
              if (hub.setupLog.isNotEmpty) ...[const SizedBox(height: 8), Text(hub.setupLog.last, style: KText.mono(11, color: K.textMuted))],
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (env != null) KButton('Install here', size: KSize.sm, onPressed: () => hub.installInto(chosen)),
                  KButton('Scripts environment', size: KSize.sm, variant: KButtonVariant.secondary, onPressed: () => hub.setupPython(scriptsDir, cfg: cfg)),
                  KButton('Check again', size: KSize.sm, variant: KButtonVariant.ghost, onPressed: () => hub.recheckPython(chosen)),
                ],
              ),
            ],
          ),
        ),
      ];
    }
    return [
      const SizedBox(height: 12),
      KNotice(
        tone: Tone.info,
        title: hub.settingUp ? 'Setting up Python' : 'One-time setup',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              hub.settingUp
                  ? (hub.setupLog.lastOrNull ?? '…')
                  : 'Scripts need the koebelt-dash-scripts package. dash can create a Python environment for them in the scripts folder (.venv) and install it there; your own packages (OpenCV, PyTorch…) go there too.',
            ),
            if (!hub.settingUp) ...[
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: KButton('Set up Python', size: KSize.sm, onPressed: () => hub.setupPython(scriptsDir, cfg: cfg)),
              ),
            ],
          ],
        ),
      ),
    ];
  }

  /// What the last install, update or setup did: a success fades after a few
  /// seconds, a failure stays until dismissed or tried again.
  Widget _setupResult(({bool ok, String text}) r) => KNotice(
    tone: r.ok ? Tone.positive : Tone.negative,
    child: Row(
      children: [
        Expanded(child: Text(r.text)),
        if (!r.ok) KIconButton('x', label: 'Dismiss', size: KSize.sm, variant: KIconButtonVariant.bare, onPressed: hub.dismissResult),
      ],
    ),
  );

  Widget _runButtons(BuildContext context, ScriptConfig cfg, ScriptRun? run, bool running) {
    // Here: a Python dash checked has koebelt-dash-scripts.
    final where = hub.hostFor(cfg) != null || (ScriptHub.canRunHere && hub.port != null && (hub.envOf(hub.pythonFor(cfg))?.hasPackage ?? false));
    final t = _target(cfg);
    final canRun = where && t.why == null;
    final button = Row(
      children: [
        Expanded(
          child: running
              ? KButton('Stop script', variant: KButtonVariant.secondary, fullWidth: true, iconLeft: const KIcon('square', size: 16), onPressed: () => run!.stop())
              : KButton('Run', fullWidth: true, iconLeft: const KIcon('play', size: 14, color: K.textOnAccent), onPressed: canRun ? onRun : null),
        ),
        if (running) ...[
          const SizedBox(width: 8),
          KIconButton(
            'replay',
            label: 'Restart',
            onPressed: () async {
              await run!.stop();
              onRun();
            },
          ),
        ],
      ],
    );
    if (t.why == null || running) return button;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        button,
        const SizedBox(height: 12),
        KNotice(
          tone: Tone.warning,
          title: '${t.name} does not fit this script',
          child: Text('${t.why} Choose another device above, or change the # requires: line.'),
        ),
      ],
    );
  }

  Widget _settings(ScriptConn c) => _Section(
    'Settings',
    children: [
      for (final e in c.settings.entries)
        if (e.value['value'] is bool)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Expanded(child: Text('${e.value['label'] ?? e.key}', style: KText.bodySm.copyWith(color: K.textPrimary))),
                KSwitch(checked: e.value['value'] == true, onChanged: (v) => hub.setSetting(c, e.key, v)),
              ],
            ),
          )
        else if (e.value['value'] is num)
          _NumberSetting(
            label: '${e.value['label'] ?? e.key}',
            value: (e.value['value'] as num).toDouble(),
            min: (e.value['min'] as num?)?.toDouble(),
            max: (e.value['max'] as num?)?.toDouble(),
            onChanged: (v) => hub.setSetting(c, e.key, v),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Expanded(child: Text(e.key, style: KText.bodySm.copyWith(color: K.textPrimary))),
                Text('${e.value['value']}', style: KText.mono(12)),
              ],
            ),
          ),
    ],
  );

  Widget _triggers(BuildContext context, ScriptConfig cfg, ScriptConn? conn, DeviceKind? kind) {
    final events = <String>{...?conn?.triggers.keys, for (final b in cfg.bindings) b.event}.toList();
    Future<void> edit([TriggerBinding? b]) async {
      final r = await showTriggerDialog(context, d, events: events, kind: kind ?? DeviceKind.generic, existing: b);
      if (r == null) return;
      if (b != null) cfg.bindings[cfg.bindings.indexOf(b)] = r;
      if (b == null) cfg.bindings.add(r);
      hub.saveConfigs();
      d.emit();
    }

    return _Section(
      'Triggers',
      right: KButton('Add', size: KSize.sm, variant: KButtonVariant.ghost, iconLeft: const KIcon('plus', size: 14), onPressed: () => edit()),
      children: [
        if (events.isEmpty)
          Text('Buttons, keys, controller buttons, conditions and timers that send events to the script. Declare them with @dev.trigger(…), or add them here.', style: KText.bodySm.copyWith(color: K.textMuted)),
        for (final ev in events) _TriggerRow(d: d, cfg: cfg, conn: conn, event: ev, decl: conn?.triggers[ev], onEdit: edit),
      ],
    );
  }

  Widget _limits(BuildContext context, ScriptConfig cfg, DeviceKind? kind) {
    final l = cfg.limits;
    Widget row(String k, String v, {bool muted = false}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(k, style: KText.bodySm.copyWith(color: K.textMuted))),
          Text(v, style: KText.mono(12, color: muted ? K.textMuted : K.textPrimary)),
        ],
      ),
    );
    return _Section(
      'Limits',
      right: KButton(
        'Edit',
        size: KSize.sm,
        variant: KButtonVariant.ghost,
        onPressed: () => showLimitsDialog(
          context,
          l,
          kind: kind,
          onChanged: () {
            hub.saveConfigs();
            d.emit();
          },
        ),
      ),
      children: [
        row('Max speed', '${(l.maxSpeed * 100).round()} %'),
        row('Geofence', l.fence == 0 ? 'off' : '${l.fence.round()} m from home', muted: l.fence == 0),
        if (kind == null || kind == DeviceKind.drone) row('Ceiling', l.ceiling == 0 ? 'off' : '${l.ceiling.round()} m', muted: l.ceiling == 0),
        row('Arming, take-off', l.allowArm ? 'allowed' : 'not allowed', muted: !l.allowArm),
        row('Parameter writes', l.allowParams ? 'allowed' : 'not allowed', muted: !l.allowParams),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.label, {required this.children, this.right});
  final String label;
  final List<Widget> children;
  final Widget? right;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        children: [
          Expanded(child: MonoLabel(label)),
          ?right,
        ],
      ),
      const SizedBox(height: 10),
      ...children,
    ],
  );
}

class _NumberSetting extends StatelessWidget {
  const _NumberSetting({required this.label, required this.value, required this.onChanged, this.min, this.max});
  final String label;
  final double value;
  final double? min, max;
  final ValueChanged<double> onChanged;
  @override
  Widget build(BuildContext context) {
    final lo = min ?? 0, hi = max ?? (value.abs() * 2).clamp(1, double.infinity).toDouble();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text(label, style: KText.bodySm.copyWith(color: K.textPrimary))),
              Text(value.abs() >= 100 ? value.toStringAsFixed(0) : value.toStringAsFixed(2), style: KText.mono(12)),
            ],
          ),
          KSlider(value: value.clamp(lo, hi), min: lo, max: hi, onChanged: onChanged),
        ],
      ),
    );
  }
}

/// One event: its on-screen control and every binding that fires it.
class _TriggerRow extends StatelessWidget {
  const _TriggerRow({required this.d, required this.cfg, required this.conn, required this.event, required this.decl, required this.onEdit});
  final Dash d;
  final ScriptConfig cfg;
  final ScriptConn? conn;
  final String event;
  final Map<String, dynamic>? decl;
  final Future<void> Function([TriggerBinding?]) onEdit;

  @override
  Widget build(BuildContext context) {
    final hub = d.scripts, c = conn;
    final bindings = cfg.bindings.where((b) => b.event == event).toList();
    final screen = bindings.where((b) => b.onScreen).firstOrNull;
    final kind = screen?.source ?? (decl == null ? null : sourceForKind('${decl!['kind']}'));
    Widget control = const SizedBox.shrink();
    if (kind == TriggerSource.toggle) {
      control = KSwitch(checked: cfg.values[event] == true, onChanged: c == null ? null : (v) => hub.setToggle(c, event, v));
    } else if (kind == TriggerSource.button) {
      control = KButton('Fire', size: KSize.sm, variant: KButtonVariant.secondary, onPressed: c == null ? null : () => hub.press(c, event));
    }
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: K.borderHairline))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text(event, style: KText.bodySm.copyWith(color: K.textPrimary))),
              control,
            ],
          ),
          if (kind == TriggerSource.slider)
            KSlider(
              value: ((cfg.values[event] as num?)?.toDouble() ?? screen?.min ?? 0).clamp(screen?.min ?? 0, screen?.max ?? 1),
              min: screen?.min ?? (decl?['min'] as num?)?.toDouble() ?? 0,
              max: screen?.max ?? (decl?['max'] as num?)?.toDouble() ?? 1,
              onChanged: c == null ? null : (v) => hub.setSlider(c, event, v),
            ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final b in bindings) _chip(b, c),
              if (bindings.isEmpty) Text('Not bound yet', style: KText.mono(11, color: K.textMuted)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(TriggerBinding b, ScriptConn? c) {
    final w = b.source == TriggerSource.condition ? c?.triggerState.watches[b] : null;
    final color = w?.error != null
        ? K.negative
        : w?.now == true
        ? K.accent
        : K.textSecondary;
    return Pressable(
      onTap: () => onEdit(b),
      builder: (_, hover, _) => Container(
        padding: const EdgeInsets.fromLTRB(8, 4, 4, 4),
        decoration: BoxDecoration(
          color: hover ? K.surfaceHover : null,
          border: Border.all(color: w?.error != null ? K.negative : K.borderSubtle),
          borderRadius: BorderRadius.circular(K.radiusControl),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Tooltip(
              message: w?.error ?? (w?.now == null ? '' : 'Now ${w!.now}'),
              child: Text(b.source == TriggerSource.condition ? b.describe(padSourceLabel) : b.describe(padSourceLabel).toUpperCase(), style: KText.mono(11, color: color)),
            ),
            const SizedBox(width: 4),
            Pressable(
              onTap: () {
                cfg.bindings.remove(b);
                d.scripts.saveConfigs();
                d.emit();
              },
              builder: (_, h, _) => KIcon('x', size: 12, color: h ? K.textPrimary : K.textFaint),
            ),
          ],
        ),
      ),
    );
  }
}

class _Dropdown<T> extends StatelessWidget {
  const _Dropdown({required this.value, required this.items, required this.onChanged});
  final T value;
  final Map<T, String> items;
  final ValueChanged<T> onChanged;
  @override
  Widget build(BuildContext context) => Container(
    height: 34,
    padding: const EdgeInsets.symmetric(horizontal: 10),
    decoration: BoxDecoration(
      color: K.surfaceSunken,
      border: Border.all(color: K.borderHairline),
      borderRadius: BorderRadius.circular(K.radiusControl),
    ),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<T>(
        value: items.containsKey(value) ? value : items.keys.firstOrNull,
        isExpanded: true,
        dropdownColor: K.surfaceRaised,
        icon: const KIcon('chevron-down', size: 14, color: K.textMuted),
        style: KText.mono(12),
        items: [
          for (final e in items.entries) DropdownMenuItem<T>(value: e.key, child: Text(e.value, overflow: TextOverflow.ellipsis, style: KText.mono(12))),
        ],
        onChanged: (v) => onChanged(v as T),
      ),
    ),
  );
}

/// The script's output: its own lines, and dash's about it.
class ScriptConsole extends StatefulWidget {
  const ScriptConsole({super.key, required this.lines, this.hz, this.phone = false, this.onLine});
  final List<ConsoleLine> lines;
  final double? hz;
  final bool phone;

  /// Tapped a traceback line that names a line of the script.
  final ValueChanged<int>? onLine;
  @override
  State<ScriptConsole> createState() => _ScriptConsoleState();
}

class _ScriptConsoleState extends State<ScriptConsole> {
  final _scroll = ScrollController();
  int _seen = 0;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lines = widget.lines;
    if (lines.length != _seen) {
      _seen = lines.length;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) _scroll.jumpTo(_scroll.position.maxScrollExtent);
      });
    }
    String two(int n) => n.toString().padLeft(2, '0');
    return Container(
      color: K.surfaceDeep,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
            child: Row(
              children: [
                const Expanded(child: MonoLabel('Console')),
                if (widget.hz != null) Text('loop ${widget.hz!.toStringAsFixed(1)} Hz', style: KText.mono(11, color: K.textMuted)),
              ],
            ),
          ),
          Expanded(
            child: lines.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text('print() output and errors show here.', style: KText.mono(12, color: K.textFaint)),
                  )
                : SelectionArea(
                    child: ListView.builder(
                      controller: _scroll,
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                      itemCount: lines.length,
                      itemBuilder: (_, i) {
                        final l = lines[i];
                        final c = switch (l.level) {
                          'warn' => K.warning,
                          'err' => K.negative,
                          'trig' => K.accent,
                          'info' => K.textMuted,
                          _ => K.textSecondary,
                        };
                        // A traceback's line, or an error's --> script.py:14.
                        final line = RegExp(r'File ".*?", line (\d+)|--> .*?:(\d+)\s*$').firstMatch(l.text);
                        final text = Text(l.text, style: KText.mono(12, color: c, height: 1.5, w: FontWeight.w400));
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!widget.phone) ...[
                              Text('${two(l.at.hour)}:${two(l.at.minute)}:${two(l.at.second)}', style: KText.mono(12, color: K.textFaint, height: 1.5)),
                              const SizedBox(width: 12),
                            ],
                            Expanded(
                              child: line != null && widget.onLine != null
                                  ? Pressable(onTap: () => widget.onLine!(int.parse(line[1] ?? line[2]!)), builder: (_, _, _) => text)
                                  : text,
                            ),
                          ],
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

/// Title for the console of a script that is not dash's (started in a terminal).
String outsideLabel(ScriptConn c) => '${ScriptLibrary.titleOf(c.name.replaceAll(RegExp(r'\.py$'), ''))} · from outside dash';

/// On Control: the scripts working with the focused device, their state, and
/// the triggers pinned there. Nothing when no script is.
class ScriptControls extends StatelessWidget {
  const ScriptControls(this.d, {super.key});
  final Dash d;
  @override
  Widget build(BuildContext context) {
    final l = d.focus, hub = d.scripts;
    if (l == null) return const SizedBox.shrink();
    final conns = hub.conns.where((c) => c.device == l.id).toList();
    if (conns.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final c in conns) ...[
          _state(c),
          for (final b in c.config.bindings.where((b) => b.pinned && b.onScreen))
            if (b.source == TriggerSource.toggle)
              Pressable(
                onTap: () => hub.setToggle(c, b.event, c.config.values[b.event] != true),
                builder: (_, _, _) => KTag('${b.event} · ${c.config.values[b.event] == true ? 'on' : 'off'}', tone: c.config.values[b.event] == true ? TagTone.accent : TagTone.neutral, height: 32),
              )
            else if (b.source == TriggerSource.button)
              KButton(b.event, size: KSize.sm, variant: KButtonVariant.secondary, onPressed: () => hub.press(c, b.event)),
        ],
      ],
    );
  }

  Widget _state(ScriptConn c) {
    final hub = d.scripts, dr = c.drive;
    final (String text, Color color, VoidCallback? resume) = c.blocked != null
        ? ('${c.name} stopped', K.negative, () => hub.unblock(c))
        : dr?.paused == true
        ? ('You have the sticks', K.warning, () => hub.resume(dr!.link))
        : dr != null
        ? ('${c.name} drives', K.positive, null)
        : (c.name, K.textSecondary, null);
    return Tooltip(
      message: c.blocked ?? '',
      child: Container(
        height: 32,
        padding: EdgeInsets.only(left: 12, right: resume == null ? 12 : 4),
        decoration: BoxDecoration(
          border: Border.all(color: color.withValues(alpha: .6)),
          borderRadius: BorderRadius.circular(K.radiusPill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            PulseDot(color: color, animate: dr != null && !dr.paused),
            const SizedBox(width: 8),
            Text(text.toUpperCase(), style: KText.label(color: color)),
            if (resume != null) ...[
              const SizedBox(width: 8),
              KButton('Resume', size: KSize.sm, variant: KButtonVariant.ghost, onPressed: resume),
            ],
          ],
        ),
      ),
    );
  }
}
