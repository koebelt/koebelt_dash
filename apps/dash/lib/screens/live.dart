import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../core/dash.dart';
import '../theme/tokens.dart';
import '../ui/components.dart';
import '../ui/icons.dart';
import '../viz/viz.dart';
import 'common.dart';
import 'main_view.dart';
import '../video/video_view.dart';
import '../viz/map_view.dart';
import 'tiles.dart';

const _grid = 12;

class LiveScreen extends StatefulWidget {
  const LiveScreen(this.d, {super.key, required this.w, required this.onOpen});
  final Dash d;
  final double w;
  final ValueChanged<String> onOpen;
  @override
  State<LiveScreen> createState() => _LiveScreenState();
}

class _LiveScreenState extends State<LiveScreen> {
  String get view => widget.d.liveView;
  set view(String v) => widget.d.liveView = v;
  bool edit = false;

  @override
  Widget build(BuildContext context) {
    final d = widget.d, phone = widget.w < 600, wall = d.layout == 'wall';
    void setLayout(String l) {
      setState(() => edit = false);
      d.layout = l;
      d.emit();
    }

    final bar = Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        color: K.surfacePage,
        border: Border(bottom: BorderSide(color: K.borderHairline)),
      ),
      child: Row(
        children: [
          Seg(small: true, items: const ['HUD', 'WALL'], value: wall ? 'WALL' : 'HUD', onChanged: (v) => setLayout(v == 'WALL' ? 'wall' : 'hud')),
          if (!wall) ...[
            const SizedBox(width: 8),
            if (!phone)
              ViewSeg(d, view: view, onChanged: (v) => setState(() => view = v))
            else if (viewItems(d, cameras3d: false).length > 1)
              ViewSeg(d, view: view, cameras3d: false, onChanged: (v) => setState(() => view = v)),
          ],
          const Spacer(),
          RecordButton(d, label: !phone || d.recording),
          const SizedBox(width: 8),
          LayersBtn(d),
          if (!wall && !edit) ...[
            const SizedBox(width: 8),
            if (phone)
              KIconButton('pencil', label: 'Edit layout', size: KSize.sm, onPressed: () => setState(() => edit = true))
            else
              KButton('Edit layout', size: KSize.sm, variant: KButtonVariant.secondary, onPressed: () => setState(() => edit = true)),
          ],
        ],
      ),
    );
    Widget body;
    if (wall) {
      final cols = phone ? 2 : math.max(2, ((widget.w - 24) / 250).floor());
      final ts = tilesFor(d);
      body = SingleChildScrollView(
        padding: EdgeInsets.all(phone ? 12 : 16),
        child: LayoutBuilder(
          builder: (context, c) {
            final gap = phone ? 8.0 : 12.0, rowH = phone ? 150.0 : 170.0;
            final cw = (c.maxWidth - gap * (cols - 1)) / cols;
            // 2×2 scene first, then tiles flow around it (CSS grid auto-placement).
            final occupied = <String>{};
            final placed = <Widget>[];
            int row = 0, col = 0;
            void mark(int r, int cc, int w, int h) {
              for (var i = r; i < r + h; i++) {
                for (var j = cc; j < cc + w; j++) {
                  occupied.add('$i:$j');
                }
              }
            }

            Positioned pos(int r, int cc, int w, int h, Widget child) =>
                Positioned(left: cc * (cw + gap), top: r * (rowH + gap), width: cw * w + gap * (w - 1), height: rowH * h + gap * (h - 1), child: child);
            placed.add(pos(0, 0, 2, 2, _WallScene(d: d, view: view, setView: (v) => setState(() => view = v))));
            mark(0, 0, 2, 2);
            var maxRow = 2;
            for (final t in ts) {
              while (occupied.contains('$row:$col')) {
                col++;
                if (col >= cols) {
                  col = 0;
                  row++;
                }
              }
              placed.add(pos(row, col, 1, 1, Tile(d, t, onOpen: () => widget.onOpen(t.id), compact: phone)));
              mark(row, col, 1, 1);
              maxRow = math.max(maxRow, row + 1);
            }
            return SizedBox(
              height: maxRow * (rowH + gap) - gap,
              child: Stack(children: placed),
            );
          },
        ),
      );
    } else {
      body = HudView(d: d, w: widget.w, onOpen: widget.onOpen, view: view, edit: edit, setEdit: (v) => setState(() => edit = v));
    }
    return Column(
      children: [
        bar,
        Expanded(child: body),
      ],
    );
  }
}

class _WallScene extends StatelessWidget {
  const _WallScene({required this.d, required this.view, required this.setView});
  final Dash d;
  final String view;
  final ValueChanged<String> setView;
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(K.radiusCard),
    child: Container(
      decoration: BoxDecoration(
        color: K.surfaceDeep,
        border: Border.all(color: K.borderHairline),
        borderRadius: BorderRadius.circular(K.radiusCard),
      ),
      child: Stack(
        children: [
          Positioned.fill(child: MainView(d, view: view)),
          Positioned(
            top: 10,
            left: 10,
            child: ViewSeg(d, view: view, onChanged: setView),
          ),
        ],
      ),
    ),
  );
}

class LayersBtn extends StatefulWidget {
  const LayersBtn(this.d, {super.key});
  final Dash d;
  @override
  State<LayersBtn> createState() => _LayersBtnState();
}

class _LayersBtnState extends State<LayersBtn> {
  final _link = LayerLink();
  OverlayEntry? _entry;

  void _toggle() {
    if (_entry != null) {
      _close();
      return;
    }
    _entry = OverlayEntry(
      builder: (_) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(behavior: HitTestBehavior.translucent, onTap: _close),
          ),
          CompositedTransformFollower(
            link: _link,
            targetAnchor: Alignment.bottomRight,
            followerAnchor: Alignment.topRight,
            offset: const Offset(0, 8),
            child: ListenableBuilder(
              listenable: widget.d,
              builder: (_, _) => Material(
                type: MaterialType.transparency,
                child: Container(
                  width: 220,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: K.surfaceRaised,
                    border: Border.all(color: K.borderSubtle),
                    borderRadius: BorderRadius.circular(K.radiusCard),
                    boxShadow: K.shadowOverlay,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const MonoLabel('3D scene layers'),
                      for (final l in const [
                        ['cloud', 'Point cloud'],
                        ['trail', 'Trajectory'],
                        ['radar', 'Radar tracks'],
                        ['grid', 'Ground grid'],
                      ]) ...[
                        const SizedBox(height: 14),
                        KSwitch(
                          label: l[1],
                          checked: widget.d.layers[l[0]] ?? true,
                          onChanged: (v) {
                            widget.d.layers = {...widget.d.layers, l[0]: v};
                            widget.d.emit();
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
    Overlay.of(context).insert(_entry!);
    setState(() {});
  }

  void _close() {
    _entry?.remove();
    _entry = null;
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _entry?.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => CompositedTransformTarget(
    link: _link,
    child: KIconButton(
      'layers',
      label: 'Scene layers',
      size: KSize.sm,
      variant: _entry != null ? KIconButtonVariant.solid : KIconButtonVariant.outline,
      onPressed: _toggle,
    ),
  );
}

/// Frosted panel floating over the 3D scene.
class Glass extends StatelessWidget {
  const Glass({super.key, required this.child, this.padding = const EdgeInsets.all(10), this.border});
  final Widget child;
  final EdgeInsets padding;
  final BoxBorder? border;
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(K.radiusCard),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: K.inkA62,
          border: border ?? Border.all(color: K.borderHairline),
          borderRadius: BorderRadius.circular(K.radiusCard),
        ),
        child: child,
      ),
    ),
  );
}

class HudPanel extends StatelessWidget {
  const HudPanel({super.key, required this.title, required this.child});
  final String title;
  final Widget child;
  @override
  Widget build(BuildContext context) => Glass(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MonoLabel(title, size: 9),
        const SizedBox(height: 6),
        Expanded(child: child),
      ],
    ),
  );
}

class HudView extends StatefulWidget {
  const HudView({super.key, required this.d, required this.w, required this.onOpen, required this.view, required this.edit, required this.setEdit});
  final Dash d;
  final double w;
  final ValueChanged<String> onOpen;
  final String view;
  final bool edit;
  final ValueChanged<bool> setEdit;
  @override
  State<HudView> createState() => _HudViewState();
}

class _HudViewState extends State<HudView> {
  List<HudItem>? draft;
  String? _dev, _cls;
  Offset _acc = Offset.zero;
  HudItem? _base;

  String get cls => widget.w < 600
      ? 'phone'
      : widget.w < 1100
      ? 'tablet'
      : 'desktop';

  List<HudItem> get layout => draft ?? widget.d.savedHud(cls) ?? hudDefault(widget.d.kind, cls);

  void _add() {
    final d = widget.d, lay = layout;
    final unused = allTiles(d).where((t) => !lay.any((l) => l.id == t.id)).toList();
    showKDialog(
      context,
      builder: (ctx) => KDialogPanel(
        title: 'Add widget',
        width: 420,
        onClose: () => Navigator.pop(ctx),
        children: [
          Text('Widgets are saved for ${d.device?.name ?? 'this device'} on $cls screens.'),
          Column(
            children: [
              hairline,
              for (final t in unused)
                Pressable(
                  onTap: () {
                    setState(() => draft = [...lay.map((e) => e.copy()), HudItem(t.id, 4, 4, cls == 'phone' ? 6 : 3, 3)]);
                    Navigator.pop(ctx);
                  },
                  builder: (_, h, _) => Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: K.borderHairline)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(t.titleFor(d.kind), style: KText.bodyMd.copyWith(color: h ? K.textAccent : K.textPrimary)),
                              const SizedBox(height: 6),
                              MonoLabel(t.src),
                            ],
                          ),
                        ),
                        const KIcon('plus', size: 16, color: K.textPrimary),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.d;
    if (_dev != d.deviceId || _cls != cls) {
      draft = null;
      _dev = d.deviceId;
      _cls = cls;
    }
    final edit = widget.edit, lay = layout, all = allTiles(d);
    final unused = all.where((t) => !lay.any((l) => l.id == t.id)).toList();
    return Container(
      color: K.surfaceDeep,
      child: Stack(
        children: [
          Positioned.fill(child: MainView(d, view: widget.view, attribution: false)),
          Positioned.fill(
            left: 8,
            top: 8,
            right: 8,
            bottom: 8,
            child: LayoutBuilder(
              builder: (context, c) {
                final cw = c.maxWidth / _grid, ch = c.maxHeight / _grid;
                return Stack(
                  children: [
                    if (edit)
                      Positioned.fill(
                        child: IgnorePointer(child: CustomPaint(painter: _GridPainter())),
                      ),
                    for (var i = 0; i < lay.length; i++)
                      if (all.any((t) => t.id == lay[i].id)) _widget(lay, i, all.firstWhere((t) => t.id == lay[i].id), cw, ch),
                  ],
                );
              },
            ),
          ),
          if (edit)
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: K.surfaceRaised,
                    border: Border.all(color: K.borderSubtle),
                    borderRadius: BorderRadius.circular(K.radiusCard),
                    boxShadow: K.shadowOverlay,
                  ),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      KButton(
                        'Add widget',
                        size: KSize.sm,
                        variant: KButtonVariant.secondary,
                        iconLeft: const KIcon('plus', size: 14),
                        onPressed: unused.isEmpty ? null : _add,
                      ),
                      KButton(
                        'Reset',
                        size: KSize.sm,
                        variant: KButtonVariant.ghost,
                        onPressed: () {
                          d.saveHud(cls, null);
                          setState(() => draft = null);
                        },
                      ),
                      KButton(
                        'Cancel',
                        size: KSize.sm,
                        variant: KButtonVariant.ghost,
                        onPressed: () {
                          setState(() => draft = null);
                          widget.setEdit(false);
                        },
                      ),
                      KButton(
                        'Save layout',
                        size: KSize.sm,
                        onPressed: () {
                          if (draft != null) d.saveHud(cls, draft);
                          setState(() => draft = null);
                          widget.setEdit(false);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Positioned(right: 4, bottom: 4, child: MapOverlayAttribution(d, view: widget.view)),
        ],
      ),
    );
  }

  Widget _widget(List<HudItem> lay, int i, TileDef tile, double cw, double ch) {
    final it = lay[i], edit = widget.edit, d = widget.d, phone = cls == 'phone';
    final readout = tile.id == 'readout';
    void start(DragStartDetails _) {
      draft ??= [for (final e in lay) e.copy()];
      _acc = Offset.zero;
      _base = draft![i].copy();
    }

    void update(DragUpdateDetails e, bool size) {
      _acc += e.delta;
      final dx = (_acc.dx / cw).round(), dy = (_acc.dy / ch).round(), o = _base!;
      setState(() {
        final t = draft![i];
        if (!size) {
          t.x = (o.x + dx).clamp(0, _grid - o.w);
          t.y = (o.y + dy).clamp(0, _grid - o.h);
        } else {
          t.w = (o.w + dx).clamp(2, _grid - o.x);
          t.h = (o.h + dy).clamp(2, _grid - o.y);
        }
      });
    }

    final panel = GestureDetector(
      onTap: edit || readout ? null : () => widget.onOpen(tile.id),
      onPanStart: edit ? start : null,
      onPanUpdate: edit ? (e) => update(e, false) : null,
      child: MouseRegion(
        cursor: edit
            ? SystemMouseCursors.move
            : readout
            ? SystemMouseCursors.basic
            : SystemMouseCursors.click,
        child: Glass(
          padding: EdgeInsets.all(phone ? 8 : 10),
          border: edit ? Border.all(color: K.accent) : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 12,
                child: Row(
                  children: [
                    Expanded(child: MonoLabel(tile.titleFor(d.kind), size: 9, maxLines: 1)),
                    if (!edit && !readout)
                      Flexible(
                        child: Text(tile.val(d), maxLines: 1, overflow: TextOverflow.clip, softWrap: false, style: KText.mono(10)),
                      ),
                    if (edit)
                      GestureDetector(
                        onTap: () => setState(
                          () => draft = [
                            for (var j = 0; j < lay.length; j++)
                              if (j != i) lay[j].copy(),
                          ],
                        ),
                        child: const MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: KIcon('x', size: 14, color: K.textPrimary),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Expanded(
                child: IgnorePointer(
                  ignoring: edit,
                  child: Opacity(opacity: edit ? .6 : 1, child: tile.body(d)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    return Positioned(
      left: it.x * cw,
      top: it.y * ch,
      width: it.w * cw,
      height: it.h * ch,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Stack(
          children: [
            Positioned.fill(child: panel),
            if (edit)
              Positioned(
                right: -4,
                bottom: -4,
                child: GestureDetector(
                  onPanStart: start,
                  onPanUpdate: (e) => update(e, true),
                  child: MouseRegion(
                    cursor: SystemMouseCursors.resizeDownRight,
                    child: Container(
                      width: 24,
                      height: 24,
                      alignment: Alignment.bottomRight,
                      padding: const EdgeInsets.all(4),
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          border: Border(
                            right: BorderSide(color: K.accent, width: 2),
                            bottom: BorderSide(color: K.accent, width: 2),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final p = Paint()..color = K.whiteA08;
    for (var i = 0; i <= _grid; i++) {
      c.drawLine(Offset(s.width * i / _grid, 0), Offset(s.width * i / _grid, s.height), p);
      c.drawLine(Offset(0, s.height * i / _grid), Offset(s.width, s.height * i / _grid), p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ---------------------------------------------------------------- sensor detail
List<double> _stats(List<double?> a) {
  final v = a.whereType<double>().toList();
  if (v.isEmpty) return [0, 0, 0, 0];
  return [v.last, v.reduce(math.min), v.reduce(math.max), v.reduce((x, y) => x + y) / v.length];
}

class SensorDetail extends StatefulWidget {
  const SensorDetail(this.d, {super.key, required this.id, required this.onBack, required this.w});
  final Dash d;
  final String id;
  final VoidCallback onBack;
  final double w;
  @override
  State<SensorDetail> createState() => _SensorDetailState();
}

class _SensorDetailState extends State<SensorDetail> {
  Map<String, List<double?>>? frozen;
  final off = <String>{};

  /// Detail pages get the interactive map.
  Widget _body(TileDef t) => t.id == 'gps' ? MapView(widget.d) : t.body(widget.d);

  /// Tiles without charted values (the camera): one large picture.
  Widget _picture(TileDef t, bool phone) => Padding(
    padding: phone ? const EdgeInsets.all(16) : const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            KIconButton('arrow-left', label: 'Back', onPressed: widget.onBack),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MonoLabel(t.src, color: K.textAccent),
                  const SizedBox(height: 6),
                  Text(t.titleFor(widget.d.kind), style: phone ? KText.headingSm : KText.headingMd),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: phone ? 16 : 24),
        Expanded(
          child: ClipRRect(borderRadius: BorderRadius.circular(K.radiusCard), child: t.id == 'video' ? VideoView(widget.d) : t.body(widget.d)),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final d = widget.d, t = tileById(d, widget.id), phone = widget.w < 600;
    if (t == null) return const SizedBox();
    if (t.keys.isEmpty) return _picture(t, phone);
    final cols = t.colors ?? (t.keys.length == 1 ? const [VC.lime] : axisColors);
    final visual = const ['attitude', 'gps', 'radar', 'lidar', 'joints'].contains(t.id);
    final keys = [
      for (var i = 0; i < t.keys.length; i++)
        if (!off.contains(t.keys[i])) t.keys[i],
    ];
    final kc = [
      for (var i = 0; i < t.keys.length; i++)
        if (!off.contains(t.keys[i])) cols[i % cols.length],
    ];
    final chart = Panel(
      height: phone ? 220 : 340,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: LineChart(
        d,
        keys: keys.isEmpty ? [t.keys.first] : keys,
        colors: keys.isEmpty ? [cols.first] : kc,
        sym: t.sym,
        frozen: frozen,
        labels: keys.isEmpty
            ? [t.labels.first]
            : [
                for (var i = 0; i < t.keys.length; i++)
                  if (!off.contains(t.keys[i])) t.labels[i],
              ],
        pinnable: true,
      ),
    );
    return SingleChildScrollView(
      padding: phone ? const EdgeInsets.all(16) : const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1400),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 12,
              children: [
                KIconButton('arrow-left', label: 'Back', onPressed: widget.onBack),
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: math.max(160, widget.w - 380)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      MonoLabel(t.src, color: K.textAccent),
                      const SizedBox(height: 6),
                      Text(t.titleFor(d.kind), style: phone ? KText.headingSm : KText.headingMd),
                    ],
                  ),
                ),
                KBadge(
                  frozen != null
                      ? 'Paused'
                      : d.linkLost
                      ? 'Stale'
                      : '${d.settings.rateHz} Hz live',
                  tone: frozen != null
                      ? Tone.warning
                      : d.linkLost
                      ? Tone.negative
                      : Tone.positive,
                ),
                KButton(
                  frozen != null ? 'Resume' : 'Pause',
                  size: KSize.sm,
                  variant: KButtonVariant.secondary,
                  iconLeft: KIcon(frozen != null ? 'play' : 'pause', size: 14),
                  onPressed: () => setState(() => frozen = frozen != null ? null : d.hist.freeze()),
                ),
              ],
            ),
            SizedBox(height: phone ? 16 : 24),
            if (visual && widget.w >= 900)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 10,
                    child: Panel(height: 340, padding: const EdgeInsets.all(12), child: _body(t)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(flex: 16, child: chart),
                ],
              )
            else ...[
              if (visual) ...[Panel(height: phone ? 260 : 340, padding: const EdgeInsets.all(12), child: _body(t)), const SizedBox(height: 16)],
              chart,
            ],
            SizedBox(height: phone ? 16 : 24),
            LayoutBuilder(
              builder: (context, c) {
                final min = phone ? 150.0 : 200.0;
                final n = math.max(1, (c.maxWidth / min).floor());
                final cw = (c.maxWidth - (n - 1)) / n;
                final h = frozen ?? {for (final k in t.keys) k: d.hist[k].toList()};
                return ClipRRect(
                  borderRadius: BorderRadius.circular(K.radiusCard),
                  child: Container(
                    decoration: BoxDecoration(
                      color: K.borderHairline,
                      border: Border.all(color: K.borderHairline),
                      borderRadius: BorderRadius.circular(K.radiusCard),
                    ),
                    child: Wrap(
                      spacing: 1,
                      runSpacing: 1,
                      children: [
                        for (var i = 0; i < t.keys.length; i++)
                          Builder(
                            builder: (_) {
                              final k = t.keys[i], st = _stats(h[k] ?? const []), on = !off.contains(k);
                              return Pressable(
                                onTap: () => setState(() => on ? off.add(k) : off.remove(k)),
                                builder: (_, _, _) => Opacity(
                                  opacity: on ? 1 : .45,
                                  child: Container(
                                    width: cw - .5,
                                    color: K.surfaceRaised,
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Container(width: 10, height: 2, color: cols[i % cols.length]),
                                            const SizedBox(width: 8),
                                            MonoLabel(t.labels[i]),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        Text(f1(st[0], 2), style: KText.mono(24, tracking: -.02)),
                                        const SizedBox(height: 12),
                                        MonoLabel('Min ${f1(st[1], 2)} · Max ${f1(st[2], 2)}\nMean ${f1(st[3], 2)}', size: 10, height: 1.6),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
            SizedBox(height: phone ? 16 : 24),
            Wrap(
              spacing: 24,
              runSpacing: 16,
              crossAxisAlignment: WrapCrossAlignment.end,
              children: [
                for (final r in [
                  ['Unit', t.unit],
                  ['Window', '10 s · 300 samples'],
                  ['Source', t.src],
                ])
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      MonoLabel(r[0]),
                      const SizedBox(height: 6),
                      Text(r[1], style: KText.bodySm.copyWith(color: K.textSecondary)),
                    ],
                  ),
                const MonoLabel('Tap a channel to hide it'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
