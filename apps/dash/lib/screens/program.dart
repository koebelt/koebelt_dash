import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/dash.dart';
import '../core/model.dart';
import '../core/sequence.dart';
import '../theme/tokens.dart';
import '../ui/components.dart';
import '../ui/icons.dart';
import '../viz/scene3d.dart';
import '../viz/viz.dart';
import 'common.dart' show confirmSetHome;
import 'params.dart' show ParamStepper;

/// Program and run step sequences on the connected device.
class ProgramScreen extends StatefulWidget {
  const ProgramScreen(this.d, {super.key, required this.w});
  final Dash d;
  final double w;
  @override
  State<ProgramScreen> createState() => _ProgramScreenState();
}

class _ProgramScreenState extends State<ProgramScreen> {
  String? selected;
  final _name = TextEditingController();
  String? _nameFor;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Dash get d => widget.d;

  Sequence _new(List<Sequence> seqs) {
    final q = Sequence(id: 'q${DateTime.now().microsecondsSinceEpoch}', name: 'Sequence ${seqs.length + 1}', kind: d.kind, steps: []);
    seqs.add(q);
    d.saveSequences();
    return q;
  }

  @override
  Widget build(BuildContext context) {
    final dev = d.device!, w = widget.w, phone = w < 600, wide = w >= 1150;
    final seqs = d.sequencesFor(dev.id);
    var q = seqs.where((x) => x.id == selected).firstOrNull ?? seqs.firstOrNull;
    if (q != null && _nameFor != q.id) {
      _nameFor = q.id;
      _name.text = q.name;
    }
    final run = d.runner != null && d.runner!.seq.kind == d.kind ? d.runner : null;
    final runningThis = run != null && q != null && run.seq.id == q.id && (run.state == RunState.running || run.state == RunState.paused);
    final busy = run != null && (run.state == RunState.running || run.state == RunState.paused);

    final head = PageHead(
      phone: phone,
      eyebrow: '${dev.name} · ${seqs.length} ${seqs.length == 1 ? 'sequence' : 'sequences'}',
      title: 'Sequences',
      right: q == null ? null : _runControls(q, run, runningThis, busy),
    );

    final list = _SeqList(
      seqs: seqs,
      selected: q?.id,
      running: busy ? run.seq.id : null,
      phone: !wide,
      onSelect: (id) => setState(() => selected = id),
      onNew: () => setState(() => selected = _new(seqs).id),
      onDuplicate: q == null
          ? null
          : () {
              final c = q.copyAs('q${DateTime.now().microsecondsSinceEpoch}', '${q.name} copy');
              seqs.add(c);
              d.saveSequences();
              setState(() => selected = c.id);
            },
      onDelete: q == null || runningThis
          ? null
          : () {
              seqs.remove(q);
              d.saveSequences();
              setState(() => selected = null);
            },
    );

    Widget body;
    if (q == null) {
      body = Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('No sequences for ${dev.name} yet.', style: KText.bodyMd),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Text(
                'A sequence is a list of steps (${_stepExamples(d.kind)}) that the app runs one after the other, '
                'waiting for the device to confirm each one.',
                style: KText.bodySm.copyWith(color: K.textMuted),
              ),
            ),
            const SizedBox(height: 16),
            KButton('New sequence', iconLeft: const KIcon('plus', size: 16), onPressed: () => setState(() => selected = _new(seqs).id)),
          ],
        ),
      );
    } else {
      final editor = _Editor(d: d, q: q, run: runningThis ? run : null, name: _name, locked: runningThis, phone: phone);
      final preview = _Preview(d: d, q: q, run: runningThis ? run : null, height: phone ? 220 : 320);
      if (wide) {
        body = Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 240, child: list),
            const SizedBox(width: 24),
            Expanded(child: editor),
            const SizedBox(width: 24),
            SizedBox(width: 380, child: preview),
          ],
        );
      } else if (!phone) {
        body = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            list,
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: editor),
                const SizedBox(width: 20),
                SizedBox(width: math.min(340, w * .4), child: preview),
              ],
            ),
          ],
        );
      } else {
        body = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [list, const SizedBox(height: 16), preview, const SizedBox(height: 16), editor],
        );
      }
    }

    return SingleChildScrollView(
      padding: phone ? const EdgeInsets.all(16) : const EdgeInsets.fromLTRB(40, 28, 40, 40),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1500),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            head,
            if (run != null && (run.state == RunState.failed || run.state == RunState.done) && run.seq.id == q?.id) ...[
              const SizedBox(height: 16),
              KNotice(
                tone: run.state == RunState.done ? Tone.positive : Tone.warning,
                title: run.state == RunState.done ? 'Sequence complete' : 'Sequence stopped',
                child: Text(run.message),
              ),
            ],
            if (d.kind == DeviceKind.rocket) ...[
              const SizedBox(height: 16),
              const KNotice(
                tone: Tone.info,
                title: 'Flight sequence',
                child: Text(
                  'The flight computer runs launch, apogee and recovery on board. Set deployment on the Tune screen; use sequences here for pad checks.',
                ),
              ),
            ],
            SizedBox(height: phone ? 16 : 24),
            body,
          ],
        ),
      ),
    );
  }

  String _stepExamples(DeviceKind k) => switch (k) {
    DeviceKind.drone => 'take off, fly to waypoints, wait, land',
    DeviceKind.rover => 'drive to waypoints, wait, change speed',
    DeviceKind.arm => 'move to poses, open or close the gripper',
    DeviceKind.bench => 'hold a throttle, ramp between two throttles',
    _ => 'wait, set a mode, send commands',
  };

  Widget _runControls(Sequence q, SequenceRunner? run, bool runningThis, bool busy) {
    final s = d.liveTel;
    final blocked = !d.hasDevice || d.replay != null || s.estop || d.linkLost || q.steps.isEmpty;
    final why = d.replay != null
        ? 'Exit replay to run'
        : s.estop
        ? 'Reset the stop first'
        : d.linkLost
        ? 'Link lost'
        : q.steps.isEmpty
        ? 'Add steps first'
        : null;
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (runningThis)
          KBadge(
            [
              if (run!.onDevice) 'On device',
              if (run is DeviceSequenceRunner && run.uploading)
                'Uploading'
              else
                '${run.state == RunState.paused ? 'Paused' : 'Running'} · step ${run.index + 1} of ${q.steps.length}',
            ].join(' · '),
            tone: run.state == RunState.paused ? Tone.warning : Tone.accent,
          )
        else if (why != null)
          MonoLabel(why)
        else if (d.seqCap >= q.steps.length)
          const MonoLabel('Runs on the device: it carries on if the link drops', maxLines: 2),
        if (runningThis) ...[
          if (run!.state == RunState.running)
            KButton(
              'Pause',
              size: KSize.sm,
              variant: KButtonVariant.secondary,
              iconLeft: const KIcon('pause', size: 14),
              onPressed: run.onDevice && d.linkLost
                  ? null
                  : () {
                      run.pause();
                      d.emit();
                    },
            )
          else
            KButton(
              'Resume',
              size: KSize.sm,
              variant: KButtonVariant.secondary,
              iconLeft: const KIcon('play', size: 14),
              onPressed: d.linkLost || s.estop
                  ? null
                  : () {
                      run.resume();
                      d.emit();
                    },
            ),
          KButton(
            'Stop sequence',
            size: KSize.sm,
            variant: KButtonVariant.ghost,
            iconLeft: const KIcon('square', size: 14),
            onPressed: () {
              run.stop('Stopped from the app');
              d.emit();
            },
          ),
        ] else
          KButton('Run', size: KSize.sm, iconLeft: const KIcon('play', size: 14), onPressed: blocked || busy ? null : () => d.runSequence(q)),
      ],
    );
  }
}

// ------------------------------------------------------------------ list
class _SeqList extends StatelessWidget {
  const _SeqList({
    required this.seqs,
    required this.selected,
    required this.running,
    required this.phone,
    required this.onSelect,
    required this.onNew,
    this.onDuplicate,
    this.onDelete,
  });
  final List<Sequence> seqs;
  final String? selected, running;
  final bool phone;
  final ValueChanged<String> onSelect;
  final VoidCallback onNew;
  final VoidCallback? onDuplicate, onDelete;

  String _meta(Sequence q) {
    final t = q.steps.fold<double>(0, (a, s) => a + (s.duration ?? 0));
    return '${q.steps.length} steps${t > 0 ? ' · ${t.toStringAsFixed(0)} s timed' : ''}';
  }

  @override
  Widget build(BuildContext context) {
    final actions = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        KIconButton('plus', label: 'New sequence', size: KSize.sm, variant: KIconButtonVariant.bare, onPressed: onNew),
        KIconButton('copy', label: 'Duplicate', size: KSize.sm, variant: KIconButtonVariant.bare, onPressed: onDuplicate),
        KIconButton('trash', label: 'Delete', size: KSize.sm, variant: KIconButtonVariant.bare, onPressed: onDelete),
      ],
    );
    if (phone) {
      return Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final q in seqs) ...[
                    Pressable(
                      onTap: () => onSelect(q.id),
                      builder: (_, h, _) =>
                          KTag(running == q.id ? '▶ ${q.name}' : q.name, tone: q.id == selected ? TagTone.accent : TagTone.neutral, height: 32),
                    ),
                    const SizedBox(width: 6),
                  ],
                ],
              ),
            ),
          ),
          actions,
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(child: MonoLabel('Sequences')),
            actions,
          ],
        ),
        const SizedBox(height: 8),
        hairline,
        for (final q in seqs)
          Pressable(
            onTap: () => onSelect(q.id),
            builder: (_, h, _) {
              final on = q.id == selected;
              return Container(
                padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
                decoration: BoxDecoration(
                  color: on || h ? K.surfaceHover : Colors.transparent,
                  border: Border(
                    bottom: const BorderSide(color: K.borderHairline),
                    left: BorderSide(color: on ? K.accent : Colors.transparent, width: 2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(q.name, style: KText.bodyMd, maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                        if (running == q.id) const PulseDot(color: K.accent),
                      ],
                    ),
                    const SizedBox(height: 6),
                    MonoLabel(_meta(q)),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }
}

// ------------------------------------------------------------------ editor
class _Editor extends StatelessWidget {
  const _Editor({required this.d, required this.q, required this.run, required this.name, required this.locked, required this.phone});
  final Dash d;
  final Sequence q;
  final SequenceRunner? run;
  final TextEditingController name;
  final bool locked, phone;

  void _changed() => d.saveSequences();

  @override
  Widget build(BuildContext context) {
    final defs = stepDefs(q.kind);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const MonoLabel('Name'),
        const SizedBox(height: 8),
        KInput(
          controller: name,
          height: 40,
          style: KText.bodyMd,
          onChanged: (v) {
            q.name = v.trim().isEmpty ? q.name : v.trim();
            _changed();
          },
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(child: MonoLabel('Steps · ${q.steps.length}')),
            if (locked) const MonoLabel('Locked while running', color: K.textAccent),
          ],
        ),
        const SizedBox(height: 8),
        if (q.steps.isEmpty)
          Panel(
            child: Text('Add the first step below. Steps run top to bottom.', style: KText.bodySm.copyWith(color: K.textMuted)),
          ),
        // Drag a card by its grip to reorder. Screen readers get move up/down actions.
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          buildDefaultDragHandles: false,
          itemCount: q.steps.length,
          onReorderItem: (from, to) {
            if (locked) return;
            q.steps.insert(to, q.steps.removeAt(from));
            _changed();
          },
          proxyDecorator: (child, _, anim) => AnimatedBuilder(
            animation: anim,
            builder: (_, c) => Material(
              type: MaterialType.transparency,
              child: Opacity(opacity: 1 - .1 * anim.value, child: c),
            ),
            child: child,
          ),
          itemBuilder: (_, i) => Padding(
            key: ObjectKey(q.steps[i]),
            padding: const EdgeInsets.only(bottom: 8),
            child: _StepCard(d: d, q: q, i: i, run: run, locked: locked, phone: phone, onChanged: _changed),
          ),
        ),
        if (!locked) ...[
          const SizedBox(height: 12),
          const MonoLabel('Add step'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final def in defs)
                KButton(
                  def.label,
                  size: KSize.sm,
                  variant: KButtonVariant.secondary,
                  iconLeft: const KIcon('plus', size: 14),
                  onPressed: () {
                    final st = SeqStep.fresh(def);
                    // New waypoints and poses start from where the device is now.
                    if (def.capture != null && d.hasDevice) _capture(d, st, def.capture!);
                    q.steps.add(st);
                    _changed();
                  },
                ),
            ],
          ),
        ],
      ],
    );
  }
}

void _capture(Dash d, SeqStep st, String what) {
  final t = d.liveTel;
  double r(double v) => (v * 2).roundToDouble() / 2;
  if (what == 'pos') {
    st.p['x'] = r(t.pos[0]);
    st.p['y'] = r(t.pos[1]);
    if (st.p.containsKey('z')) st.p['z'] = math.max(1.0, r(t.pos[2]));
  } else {
    for (var i = 0; i < 6 && i < t.joints.length; i++) {
      st.p['j${i + 1}'] = (t.joints[i] * 57.2958).roundToDouble();
    }
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({required this.d, required this.q, required this.i, required this.run, required this.locked, required this.phone, required this.onChanged});
  final Dash d;
  final Sequence q;
  final int i;
  final SequenceRunner? run;
  final bool locked, phone;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final st = q.steps[i], def = stepDef(q.kind, st.type);
    final current = run != null && run!.index == i;
    final done = run != null && run!.index > i;
    final progress = current ? run!.stepProgress : null;
    Widget field(StepField f) {
      if (f.isChoice && f.choices!.isEmpty) {
        return SizedBox(
          width: 180,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MonoLabel(f.label, size: 9),
              const SizedBox(height: 6),
              _TextField(
                value: st.s(f.key),
                onChanged: (v) {
                  st.p[f.key] = v.trim();
                  onChanged();
                },
              ),
            ],
          ),
        );
      }
      if (f.isChoice) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            MonoLabel(f.label, size: 9),
            const SizedBox(height: 6),
            Seg(
              small: true,
              items: f.choices!,
              value: st.s(f.key),
              onChanged: (v) {
                st.p[f.key] = v;
                onChanged();
              },
            ),
          ],
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          MonoLabel(f.label, size: 9),
          const SizedBox(height: 6),
          ParamStepper(
            p: ParamDef(f.key, f.label, f.def, f.min, f.max, f.step, f.unit),
            value: st.n(f.key, f.def),
            mod: false,
            onChanged: (v) {
              st.p[f.key] = v;
              onChanged();
            },
          ),
        ],
      );
    }

    final card = Container(
      decoration: BoxDecoration(
        color: current ? K.surfaceHover : K.surfaceRaised,
        border: Border.all(color: current ? K.limeA32 : K.borderHairline),
        borderRadius: BorderRadius.circular(K.radiusCard),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 2, color: current ? K.accent : Colors.transparent),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 8, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        if (!locked)
                          ReorderableDragStartListener(
                            index: i,
                            child: const MouseRegion(
                              cursor: SystemMouseCursors.grab,
                              child: Tooltip(
                                message: 'Drag to reorder',
                                waitDuration: Duration(milliseconds: 600),
                                child: Padding(
                                  padding: EdgeInsets.fromLTRB(0, 6, 8, 6),
                                  child: KIcon('grip-vertical', size: 16, color: K.textMuted),
                                ),
                              ),
                            ),
                          )
                        else
                          const SizedBox(width: 24),
                        SizedBox(
                          width: 28,
                          child: Text((i + 1).toString().padLeft(2, '0'), style: KText.mono(13, color: current || done ? K.textAccent : K.textMuted)),
                        ),
                        Expanded(
                          child: Row(
                            children: [
                              Flexible(
                                child: Text(def?.label ?? st.type, style: KText.headingXs.copyWith(fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
                              ),
                              const SizedBox(width: 10),
                              if (done) const KIcon('check', size: 14, color: K.positive),
                              if (current) Flexible(child: MonoLabel(run!.message.isEmpty ? 'Running' : run!.message, color: K.textAccent, maxLines: 1)),
                            ],
                          ),
                        ),
                        if (!locked) ...[
                          KIconButton(
                            'trash',
                            label: 'Delete step',
                            size: KSize.sm,
                            variant: KIconButtonVariant.bare,
                            onPressed: () {
                              q.steps.removeAt(i);
                              onChanged();
                            },
                          ),
                        ],
                      ],
                    ),
                    if (def != null && def.fields.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.only(left: 52),
                        child: Wrap(
                          spacing: 16,
                          runSpacing: 12,
                          crossAxisAlignment: WrapCrossAlignment.end,
                          children: [
                            for (final f in def.fields) field(f),
                            if (def.capture != null && !locked)
                              KButton(
                                def.capture == 'pos' ? 'Use current position' : 'Use current pose',
                                size: KSize.sm,
                                variant: KButtonVariant.ghost,
                                iconLeft: const KIcon('crosshair', size: 14),
                                onPressed: d.hasDevice && d.replay == null
                                    ? () {
                                        _capture(d, st, def.capture!);
                                        onChanged();
                                      }
                                    : null,
                              ),
                          ],
                        ),
                      ),
                    ],
                    if (progress != null) ...[
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.only(left: 52, right: 6),
                        child: LayoutBuilder(
                          builder: (_, c) => Container(
                            height: 2,
                            color: K.ink400,
                            alignment: Alignment.centerLeft,
                            child: Container(width: c.maxWidth * progress, color: K.accent),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
    return IgnorePointer(
      ignoring: locked,
      child: Opacity(opacity: done ? .6 : 1, child: card),
    );
  }
}

class _TextField extends StatefulWidget {
  const _TextField({required this.value, required this.onChanged});
  final String value;
  final ValueChanged<String> onChanged;
  @override
  State<_TextField> createState() => _TextFieldState();
}

class _TextFieldState extends State<_TextField> {
  late final _c = TextEditingController(text: widget.value);
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => KInput(
    controller: _c,
    height: 38,
    placeholder: 'e.g. deploy',
    style: KText.mono(13, w: FontWeight.w400),
    onChanged: widget.onChanged,
  );
}

// ------------------------------------------------------------------ preview
class _Preview extends StatelessWidget {
  const _Preview({required this.d, required this.q, required this.run, required this.height});
  final Dash d;
  final Sequence q;
  final SequenceRunner? run;
  final double height;

  @override
  Widget build(BuildContext context) {
    final (title, Widget body) = switch (q.kind) {
      DeviceKind.drone || DeviceKind.rover => ('Plan · top view', LiveCanvas(_PlanPainter(d, q, run))),
      DeviceKind.bench => ('Throttle profile', LiveCanvas(_ProfilePainter(d, q, run))),
      DeviceKind.arm => ('Live view', Scene3D(d, view: 'orbit')),
      _ => ('Timeline', _Timeline(q: q, run: run)),
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MonoLabel(title),
        const SizedBox(height: 8),
        Container(
          height: height,
          decoration: BoxDecoration(
            color: K.surfaceDeep,
            border: Border.all(color: K.borderHairline),
            borderRadius: BorderRadius.circular(K.radiusCard),
          ),
          clipBehavior: Clip.antiAlias,
          child: Padding(padding: q.kind == DeviceKind.arm ? EdgeInsets.zero : const EdgeInsets.all(12), child: body),
        ),
        const SizedBox(height: 10),
        Text(_hint(q.kind), style: KText.bodySm.copyWith(color: K.textMuted)),
        if (q.kind == DeviceKind.drone || q.kind == DeviceKind.rover || q.kind == DeviceKind.arm) ...[
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: KButton(
              q.kind == DeviceKind.arm ? 'Set current pose as home' : 'Set home here',
              size: KSize.sm,
              variant: KButtonVariant.secondary,
              iconLeft: const KIcon('crosshair', size: 14),
              onPressed: !d.hasDevice || d.replay != null || d.linkLost || run != null ? null : () => confirmSetHome(context, d),
            ),
          ),
        ],
      ],
    );
  }

  String _hint(DeviceKind k) => switch (k) {
    DeviceKind.drone => 'Waypoints are metres east and north of the take-off point. The drone holds at each one before the next step. The failsafe still applies if the link drops.',
    DeviceKind.rover => 'Waypoints are metres east and north of the start point. The rover stops at each one before the next step.',
    DeviceKind.arm => 'Move the arm by hand or with jog controls, then use "Use current pose" to record it.',
    DeviceKind.bench => 'Current and temperature cutoffs on the device stay active during the sequence.',
    _ => 'Each step waits for the device to confirm before the next one starts.',
  };
}

class _Timeline extends StatelessWidget {
  const _Timeline({required this.q, required this.run});
  final Sequence q;
  final SequenceRunner? run;
  @override
  Widget build(BuildContext context) => ListView(
    children: [
      for (var i = 0; i < q.steps.length; i++)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(
            '${(i + 1).toString().padLeft(2, '0')}  ${q.steps[i].summary(q.kind)}',
            style: KText.mono(12, color: run?.index == i ? K.textAccent : K.textSecondary),
          ),
        ),
    ],
  );
}

class _PlanPainter extends FramePainter {
  _PlanPainter(super.dash, this.q, this.run);
  final Sequence q;
  final SequenceRunner? run;

  @override
  void paint(Canvas c, Size s) {
    final drone = q.kind == DeviceKind.drone;
    // Waypoints in order, with the step index they belong to.
    final pts = <(int, List<double>)>[
      (-1, [0, 0, 0]),
    ];
    for (var i = 0; i < q.steps.length; i++) {
      final st = q.steps[i];
      final last = pts.last.$2;
      switch (st.type) {
        case 'takeoff':
          pts.add((i, [last[0], last[1], st.n('alt', 6)]));
        case 'goto':
          pts.add((i, [st.n('x'), st.n('y'), drone ? st.n('z', 8) : 0]));
        case 'land':
          pts.add((i, [last[0], last[1], 0]));
        case 'rth':
          pts.add((i, [0, 0, 0]));
      }
    }
    final live = dash.hasDevice && dash.replay == null;
    final me = dash.tel.rPos;
    var minX = -5.0, maxX = 5.0, minY = -5.0, maxY = 5.0;
    for (final p in [...pts.map((e) => e.$2), if (live) me]) {
      minX = math.min(minX, p[0]);
      maxX = math.max(maxX, p[0]);
      minY = math.min(minY, p[1]);
      maxY = math.max(maxY, p[1]);
    }
    const pad = 22.0;
    final sc = math.min((s.width - pad * 2) / (maxX - minX), (s.height - pad * 2) / (maxY - minY));
    final ox = s.width / 2 - (minX + maxX) / 2 * sc, oy = s.height / 2 + (minY + maxY) / 2 * sc;
    Offset P(List<double> p) => Offset(ox + p[0] * sc, oy - p[1] * sc);

    // grid every 5 m
    final g = Paint()..color = VC.hair2;
    final step = sc * 5 < 14 ? 25.0 : 5.0;
    for (var x = (minX / step).floor() * step - step; x <= maxX + step; x += step) {
      c.drawLine(Offset(P([x, 0]).dx, 0), Offset(P([x, 0]).dx, s.height), g);
    }
    for (var y = (minY / step).floor() * step - step; y <= maxY + step; y += step) {
      c.drawLine(Offset(0, P([0, y]).dy), Offset(s.width, P([0, y]).dy), g);
    }
    drawText(c, '${step.toStringAsFixed(0)} M GRID', Offset(4, s.height - 4), VC.ink300);

    // home
    c.drawCircle(
      P([0, 0]),
      5,
      Paint()
        ..color = VC.ink300
        ..style = PaintingStyle.stroke,
    );
    drawText(c, 'HOME', P([0, 0]) + const Offset(-14, 18), VC.ink300);

    // planned path
    final cur = run?.index ?? -1;
    for (var k = 1; k < pts.length; k++) {
      final a = P(pts[k - 1].$2), b = P(pts[k].$2);
      final doneSeg = pts[k].$1 < cur;
      final active = pts[k].$1 == cur;
      c.drawLine(
        a,
        b,
        Paint()
          ..color = active
              ? VC.lime
              : doneSeg
              ? VC.lime.withValues(alpha: .35)
              : VC.white.withValues(alpha: .55)
          ..strokeWidth = active ? 2 : 1.25,
      );
    }
    for (var k = 1; k < pts.length; k++) {
      final (i, p) = pts[k];
      final o = P(p), active = i == cur;
      if (k > 1 && (P(pts[k - 1].$2) - o).distance < 1) continue; // takeoff/land at same spot
      c.drawCircle(
        o,
        active ? 6 : 4.5,
        Paint()
          ..color = active
              ? VC.lime
              : i < cur
              ? VC.lime.withValues(alpha: .5)
              : VC.white,
      );
      drawText(c, '${i + 1}${drone ? ' · ${p[2].toStringAsFixed(0)}M' : ''}', o + const Offset(8, -4), active ? VC.lime : VC.ink100);
    }

    // live trail and position
    if (live) {
      final tr = dash.tel.trail;
      if (tr.length > 1) {
        final path = Path()..moveTo(P(tr.first).dx, P(tr.first).dy);
        for (final q in tr.skip(1)) {
          path.lineTo(P(q).dx, P(q).dy);
        }
        c.drawPath(
          path,
          Paint()
            ..color = VC.info.withValues(alpha: .6)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2,
        );
      }
      c.save();
      c.translate(P(me).dx, P(me).dy);
      c.rotate(-dash.tel.rYaw);
      c.drawPath(
        Path()
          ..moveTo(9, 0)
          ..lineTo(-6, -6)
          ..lineTo(-3, 0)
          ..lineTo(-6, 6)
          ..close(),
        Paint()..color = VC.info,
      );
      c.restore();
    }
  }
}

class _ProfilePainter extends FramePainter {
  _ProfilePainter(super.dash, this.q, this.run);
  final Sequence q;
  final SequenceRunner? run;

  @override
  void paint(Canvas c, Size s) {
    // (t, throttle) breakpoints; untimed steps take no time on this chart.
    final pts = <List<double>>[
      [0, 0],
    ];
    final starts = <double>[];
    var t = 0.0, thr = 0.0;
    for (final st in q.steps) {
      starts.add(t);
      switch (st.type) {
        case 'throttle':
          thr = st.n('pct');
          pts.add([t, thr]);
          t += st.n('s');
          pts.add([t, thr]);
        case 'ramp':
          pts.add([t, st.n('from')]);
          t += st.n('s');
          thr = st.n('to');
          pts.add([t, thr]);
        case 'wait':
          t += st.n('s');
          pts.add([t, thr]);
        case 'arm':
          if (st.s('v') == 'DISARM') {
            thr = 0;
            pts.add([t, 0]);
          }
      }
    }
    final total = math.max(1.0, t);
    const L = 34.0, B = 16.0;
    double X(double v) => L + v / total * (s.width - L - 4);
    double Y(double v) => (s.height - B) - v / 100 * (s.height - B - 6);
    final g = Paint()..color = VC.hair2;
    for (final v in [0, 25, 50, 75, 100]) {
      c.drawLine(Offset(L, Y(v.toDouble())), Offset(s.width, Y(v.toDouble())), g);
      drawText(c, '$v%', Offset(0, Y(v.toDouble())), VC.ink300, middle: true);
    }
    drawText(c, '0 S', Offset(L, s.height - 2), VC.ink300);
    drawText(c, '${total.toStringAsFixed(0)} S', Offset(s.width - 4, s.height - 2), VC.ink300, align: TextAlign.right);
    final path = Path()..moveTo(X(pts.first[0]), Y(pts.first[1]));
    for (final p in pts.skip(1)) {
      path.lineTo(X(p[0]), Y(p[1]));
    }
    c.drawPath(
      path,
      Paint()
        ..color = VC.lime
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    final r = run;
    if (r != null && r.index < starts.length) {
      final at = starts[r.index] + math.min(r.stepT, r.step?.duration ?? 0);
      c.drawLine(Offset(X(at), 0), Offset(X(at), s.height - B), Paint()..color = VC.white);
    }
    // live throttle output
    if (dash.hasDevice) {
      drawText(c, 'NOW ${(dash.tel.throttleOut * 100).round()}%', Offset(s.width - 4, 10), VC.ink200, align: TextAlign.right);
    }
  }
}
