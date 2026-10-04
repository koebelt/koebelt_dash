import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/dash.dart';
import '../core/model.dart';
import '../theme/tokens.dart';
import '../ui/components.dart';
import '../viz/viz.dart';

String fmtP(double v, double step) {
  final d = math.max(0, -(math.log(step) / math.ln10 + 1e-9).floor());
  return v.toStringAsFixed(math.min(4, d));
}

double _clamp(double v, ParamDef p) {
  final r = (v / p.step).round() * p.step;
  return double.parse(r.clamp(p.min, p.max).toStringAsFixed(6));
}

class ParamStepper extends StatefulWidget {
  const ParamStepper({super.key, required this.p, required this.value, required this.onChanged, required this.mod});
  final ParamDef p;
  final double value;
  final ValueChanged<double> onChanged;
  final bool mod;
  @override
  State<ParamStepper> createState() => _ParamStepperState();
}

class _ParamStepperState extends State<ParamStepper> {
  final _c = TextEditingController();
  final _f = FocusNode();

  @override
  void initState() {
    super.initState();
    _f.addListener(() {
      if (_f.hasFocus) {
        _c.selection = TextSelection(baseOffset: 0, extentOffset: _c.text.length);
      } else {
        final v = double.tryParse(_c.text.replaceAll('−', '-'));
        if (v != null) widget.onChanged(_clamp(v, widget.p));
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    _c.dispose();
    _f.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.p, mod = widget.mod;
    if (!_f.hasFocus) _c.text = fmtP(widget.value, p.step);
    Widget btn(String t, double dv, String label) => Semantics(
      label: label,
      button: true,
      child: Pressable(
        onTap: () => widget.onChanged(_clamp(widget.value + dv, p)),
        builder: (_, h, _) => SizedBox(
          width: 36,
          height: 36,
          child: Center(
            child: Text(t, style: KText.mono(13, color: h ? K.textPrimary : K.textSecondary)),
          ),
        ),
      ),
    );
    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: K.surfaceSunken,
        border: Border.all(color: mod ? K.limeA32 : K.borderHairline),
        borderRadius: BorderRadius.circular(K.radiusControl),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          btn('−', -p.step, 'Decrease'),
          SizedBox(
            width: 64,
            child: TextField(
              controller: _c,
              focusNode: _f,
              textAlign: TextAlign.center,
              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[-−0-9.]'))],
              onSubmitted: (_) => _f.unfocus(),
              cursorColor: K.accent,
              style: KText.mono(13, color: mod ? K.textAccent : K.textPrimary),
              decoration: const InputDecoration.collapsed(hintText: ''),
            ),
          ),
          if (p.unit.isNotEmpty) Padding(padding: const EdgeInsets.only(right: 4), child: MonoLabel(p.unit, size: 9)),
          btn('+', p.step, 'Increase'),
        ],
      ),
    );
  }
}

class ParamRow extends StatelessWidget {
  const ParamRow({super.key, required this.p, required this.val, required this.dev, required this.onChanged});
  final ParamDef p;
  final double val, dev;
  final ValueChanged<double> onChanged;
  @override
  Widget build(BuildContext context) {
    final mod = (val - dev).abs() > 1e-9;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: K.borderHairline)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (mod) ...[
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(color: K.accent, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Flexible(
                          child: Text(p.label, style: KText.bodySm, overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    MonoLabel('${p.key}${mod ? ' · was ${fmtP(dev, p.step)}' : ''}', size: 9, maxLines: 1),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ParamStepper(p: p, value: val, mod: mod, onChanged: onChanged),
            ],
          ),
          const SizedBox(height: 8),
          KSlider(value: val, min: p.min, max: p.max, height: 16, onChanged: (v) => onChanged(_clamp(v, p))),
        ],
      ),
    );
  }
}

class ParamsScreen extends StatefulWidget {
  const ParamsScreen(this.d, {super.key, required this.w});
  final Dash d;
  final double w;
  @override
  State<ParamsScreen> createState() => _ParamsScreenState();
}

class _ParamsScreenState extends State<ParamsScreen> {
  String? cat, _dev;
  String q = '';
  final _qc = TextEditingController();

  @override
  void dispose() {
    _qc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.d, phone = widget.w < 600, id = d.deviceId;
    if (_dev != id) {
      _dev = id;
      cat = null;
      q = '';
      _qc.clear();
    }
    final groups = d.paramGroups[id] ?? const <ParamGroup>[];
    final dev = d.devParams ?? const {}, draft = d.draftParams ?? const {};
    final cats = <String>{for (final g in groups) g.cat}.toList();
    final curCat = cat != null && cats.contains(cat) ? cat! : (cats.isEmpty ? '' : cats.first);
    final changed = d.changedParams;
    final lost = d.linkLost, wr = d.paramWritten[id];
    final ql = q.trim().toLowerCase();
    final shown = ql.isNotEmpty
        ? [
            for (final g in groups)
              ParamGroup(g.cat, '${g.cat} · ${g.name}', g.params.where((p) => '${p.key} ${p.label} ${g.name}'.toLowerCase().contains(ql)).toList(), g.chart),
          ].where((g) => g.params.isNotEmpty).toList()
        : groups.where((g) => g.cat == curCat).toList();
    final cols = phone
        ? 1
        : widget.w >= 1200
        ? 3
        : 2;
    final dn = d.device?.name ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: phone ? const EdgeInsets.fromLTRB(16, 16, 16, 0) : const EdgeInsets.fromLTRB(40, 28, 40, 0),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: K.borderHairline)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PageHead(
                phone: phone,
                eyebrow: '$dn · firmware ${d.fwVersion ?? '—'} · ${dev.length} parameters',
                title: 'Parameters',
                right: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    changed.isNotEmpty
                        ? KBadge('${changed.length} unsaved', tone: Tone.accent)
                        : KBadge(wr != null ? 'Written $wr' : 'In sync', tone: Tone.positive),
                    KButton(
                      'Revert',
                      size: KSize.sm,
                      variant: KButtonVariant.ghost,
                      onPressed: changed.isEmpty || d.paramWriting ? null : () => d.revertParams(),
                    ),
                    KButton(
                      d.paramWriting
                          ? 'Writing…'
                          : lost
                          ? 'Link lost'
                          : 'Write to device',
                      size: KSize.sm,
                      onPressed: changed.isEmpty || d.paramWriting || lost || d.replay != null ? null : d.writeParams,
                    ),
                  ],
                ),
              ),
              SizedBox(height: phone ? 16 : 20),
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.end,
                spacing: 16,
                runSpacing: 12,
                children: [
                  Opacity(
                    opacity: ql.isNotEmpty ? .4 : 1,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: KTabs(
                        items: cats,
                        value: curCat,
                        border: false,
                        onChanged: (v) {
                          _qc.clear();
                          setState(() {
                            q = '';
                            cat = v;
                          });
                        },
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: SizedBox(
                      width: phone ? double.infinity : 260,
                      child: KInput(
                        controller: _qc,
                        placeholder: 'Search parameters',
                        height: 38,
                        style: KText.bodySm,
                        onChanged: (v) => setState(() => q = v),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: phone ? const EdgeInsets.all(16) : const EdgeInsets.fromLTRB(40, 24, 40, 40),
            child: groups.isEmpty
                ? MonoLabel(d.hasDevice ? 'Waiting for the parameter table…' : 'No device', height: 1.6)
                : shown.isEmpty
                ? MonoLabel('No parameters match "$q"')
                : LayoutBuilder(
                    builder: (_, c) {
                      final gap = phone ? 12.0 : 16.0, cw = (c.maxWidth - gap * (cols - 1)) / cols;
                      // Masonry-ish: distribute groups into columns in order.
                      final colsL = List.generate(cols, (_) => <Widget>[]);
                      for (var i = 0; i < shown.length; i++) {
                        colsL[i % cols].add(
                          Padding(
                            padding: EdgeInsets.only(bottom: gap),
                            child: _group(shown[i], dev, draft, phone),
                          ),
                        );
                      }
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (var i = 0; i < cols; i++) ...[
                            if (i > 0) SizedBox(width: gap),
                            SizedBox(
                              width: cw,
                              child: Column(children: colsL[i]),
                            ),
                          ],
                        ],
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _group(ParamGroup g, Map<String, double> dev, Map<String, double> draft, bool phone) {
    final d = widget.d;
    final gm = g.params.where((p) => ((draft[p.key] ?? 0) - (dev[p.key] ?? 0)).abs() > 1e-9).length;
    final chart = g.chart;
    return Panel(
      padding: EdgeInsets.all(phone ? 14 : 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text(g.name, style: KText.headingXs)),
              if (gm > 0)
                Pressable(
                  onTap: () => d.revertParams(g.params.map((p) => p.key)),
                  builder: (_, _, _) => MonoLabel('Revert $gm', color: K.textAccent),
                ),
            ],
          ),
          if (chart != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 80,
              child: LineChart(
                d,
                keys: chart,
                colors: chart.length > 1 ? axisColors : const [VC.lime],
                sym: chart[0][0] != 'a' && chart[0] != 'spd',
                pinnable: true,
              ),
            ),
            const SizedBox(height: 6),
            MonoLabel('Live response · ${chart.join(' ')}', size: 9),
          ],
          const SizedBox(height: 12),
          for (final p in g.params) ParamRow(p: p, val: draft[p.key] ?? p.def, dev: dev[p.key] ?? p.def, onChanged: (v) => d.setParam(p.key, v)),
        ],
      ),
    );
  }
}
