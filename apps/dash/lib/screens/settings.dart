import 'package:flutter/material.dart';

import '../core/alerts.dart';
import '../core/dash.dart';
import '../core/units.dart' as u;
import '../l10n/l10n.dart';
import '../link/protocol.dart';
import '../scripts/hosts.dart' show hostPort;
import '../scripts/library.dart' show ScriptLibrary;
import '../scripts/script_hub.dart' show ScriptHub;
import '../theme/tokens.dart';
import '../ui/components.dart';
import '../ui/icons.dart';
import '../ui/translation_note.dart';
import '../viz/map_view.dart' show tilesProblem;
import 'assistant_ui.dart';
import 'controller_settings.dart';
import 'script_dialogs.dart' show showAddHostDialog;
import 'update_ui.dart';

/// A segmented control that shrinks to the width on a small phone (long
/// words in other languages, large text) rather than overflowing.
Widget fitSeg(Widget seg) => FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: seg);

class SetRow extends StatelessWidget {
  const SetRow({super.key, required this.title, this.desc, required this.child, required this.phone});
  final String title;
  final String? desc;
  final Widget child;
  final bool phone;
  @override
  Widget build(BuildContext context) {
    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: KText.bodyMd),
        if (desc != null) ...[
          const SizedBox(height: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Text(desc!, style: KText.bodySm.copyWith(color: K.textMuted)),
          ),
        ],
      ],
    );
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: K.borderHairline)),
      ),
      child: phone
          ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [text, const SizedBox(height: 12), child])
          : Row(
              children: [
                Expanded(child: text),
                const SizedBox(width: 32),
                child,
              ],
            ),
    );
  }
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen(this.d, {super.key, required this.w, required this.go});
  final Dash d;
  final double w;
  final ValueChanged<String> go;

  /// From this width, the sections are listed beside the settings.
  static const asideFrom = 1100.0;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _scroll = ScrollController();
  final _view = GlobalKey();
  final Map<String, GlobalKey> _keys = {};
  String? _current;

  /// While a click scrolls the page, the clicked section stays highlighted
  /// (near the end, it cannot reach the top).
  bool _jumping = false;

  GlobalKey _key(String label) => _keys.putIfAbsent(label, GlobalKey.new);

  /// A section's name as shown: in the language shown, or shorter in the aside.
  String _title(String label, {bool aside = false}) =>
      {
        'Language': t.secLanguageUnits,
        'Control': t.secControl,
        'Game controller': t.secController,
        'Link and safety': t.secLink,
        'Recording': t.secRecording,
        'Alerts': t.secAlerts,
        'Map': t.secMap,
        'Pairing': t.secPairing,
        'AI assistants (MCP)': aside ? t.secAiShort : t.secAi,
        'Scripts': t.navScripts,
        'Updates': t.secUpdates,
      }[label] ??
      label;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_spy);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  /// The section at the top of the view: the last one that starts above a
  /// line a little below the top (the last one, at the bottom of the page).
  void _spy() {
    if (_jumping) return;
    final view = _view.currentContext?.findRenderObject() as RenderBox?;
    if (view == null) return;
    String? at;
    for (final e in _keys.entries) {
      final box = e.value.currentContext?.findRenderObject() as RenderBox?;
      if (box == null) continue;
      if (box.localToGlobal(Offset.zero, ancestor: view).dy <= 120) at = e.key;
    }
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 4) at = _keys.keys.last;
    at ??= _keys.keys.firstOrNull;
    if (at != _current) setState(() => _current = at);
  }

  Future<void> _jump(String label) async {
    final ctx = _keys[label]?.currentContext;
    if (ctx == null) return;
    setState(() => _current = label);
    _jumping = true;
    await Scrollable.ensureVisible(ctx, duration: K.durBase, curve: K.easeStandard);
    _jumping = false;
  }

  Widget _aside() => Container(
    width: 220,
    padding: const EdgeInsets.fromLTRB(16, 32, 8, 32),
    decoration: const BoxDecoration(
      border: Border(right: BorderSide(color: K.borderHairline)),
    ),
    child: ListView(
      children: [
        Padding(padding: const EdgeInsets.fromLTRB(12, 0, 0, 12), child: MonoLabel(t.navSettings)),
        for (final label in _keys.keys)
          Pressable(
            onTap: () => _jump(label),
            builder: (_, hover, _) {
              final on = label == (_current ?? _keys.keys.first);
              return AnimatedContainer(
                duration: K.durFast,
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                alignment: Alignment.centerLeft,
                decoration: BoxDecoration(
                  color: on
                      ? K.whiteA08
                      : hover
                      ? K.surfaceHover
                      : Colors.transparent,
                  border: Border(left: BorderSide(color: on ? K.accent : Colors.transparent, width: 2)),
                ),
                child: Text(_title(label, aside: true), style: KText.bodySm.copyWith(color: on ? K.textPrimary : K.textSecondary)),
              );
            },
          ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final d = widget.d, w = widget.w, go = widget.go;
    final st = d.settings, phone = w < 600, aside = w >= SettingsScreen.asideFrom;
    const cm = {'joysticks': 'STICKS', 'sliders': 'SLIDERS', 'tilt': 'TILT'};
    Widget section(String label, List<Widget> rows) => KeyedSubtree(
      key: _key(label),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(padding: const EdgeInsets.only(bottom: 4), child: MonoLabel(_title(label))),
          ...rows,
        ],
      ),
    );
    // The keys in page order: the controller's section is a widget of its own.
    _key('Language');
    _key('Control');
    _key('Game controller');
    final page = SingleChildScrollView(
      key: _view,
      controller: _scroll,
      padding: phone ? const EdgeInsets.all(16) : const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 860),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PageHead(phone: phone, eyebrow: 'koebelt/dash · $appVersion', title: t.navSettings),
            SizedBox(height: phone ? 20 : 32),
            section('Language', [
              SetRow(
                phone: phone,
                title: t.settingsLanguage,
                desc: t.settingsLanguageDesc,
                child: SizedBox(
                  width: phone ? double.infinity : 260,
                  child: KDropdown<String>(
                    value: st.language,
                    items: {'': t.settingsLanguageSystem(languageNames[resolveLocale('').toString()] ?? languageNames['en']!), ...languageNames},
                    onChanged: (v) => d.updateSettings((s) => s.language = v),
                  ),
                ),
              ),
              if (t.localeName != 'en') const Padding(padding: EdgeInsets.only(top: 12), child: TranslationNote()),
              SetRow(
                phone: phone,
                title: t.settingsUnits,
                desc: t.settingsUnitsDesc,
                child: SizedBox(
                  width: phone ? double.infinity : 260,
                  child: KDropdown<String>(
                    value: st.units,
                    items: {
                      '': t.settingsUnitsSystem(u.regionIsImperial() ? t.unitsImperialShort : t.unitsMetricShort),
                      'metric': t.unitsMetric,
                      'imperial': t.unitsImperial,
                    },
                    onChanged: (v) => d.updateSettings((s) => s.units = v),
                  ),
                ),
              ),
            ]),
            SizedBox(height: phone ? 20 : 32),
            section('Control', [
              SetRow(
                phone: phone,
                title: t.setInput,
                desc: t.setInputDesc,
                child: fitSeg(
                  Seg(
                    items: const ['STICKS', 'SLIDERS', 'TILT'],
                    labels: {'STICKS': t.csSticks, 'SLIDERS': t.csSliders, 'TILT': t.csTilt},
                    value: cm[st.control],
                    onChanged: (v) => d.updateSettings((s) => s.control = cm.entries.firstWhere((e) => e.value == v).key),
                  ),
                ),
              ),
              SetRow(
                phone: phone,
                title: t.setInvert,
                desc: t.setInvertDesc,
                child: KSwitch(checked: st.invertY, onChanged: (v) => d.updateSettings((s) => s.invertY = v)),
              ),
              SetRow(
                phone: phone,
                title: t.setHaptics,
                desc: t.setHapticsDesc,
                child: KSwitch(checked: st.haptics, onChanged: (v) => d.updateSettings((s) => s.haptics = v)),
              ),
            ]),
            SizedBox(height: phone ? 20 : 32),
            KeyedSubtree(
              key: _key('Game controller'),
              child: ControllerSection(d, phone: phone),
            ),
            SizedBox(height: phone ? 20 : 32),
            section('Link and safety', [
              SetRow(
                phone: phone,
                title: t.setLinkLoss,
                desc: t.setLinkLossDesc,
                child: fitSeg(Seg(items: const ['HOLD', 'RTH', 'LAND'], value: st.failsafe, onChanged: (v) => d.updateSettings((s) => s.failsafe = v))),
              ),
              SetRow(
                phone: phone,
                title: t.setRate,
                desc: t.setRateDesc,
                child: fitSeg(Seg(items: const ['10', '30', '60'], value: '${st.rateHz}', onChanged: (v) => d.updateSettings((s) => s.rateHz = int.parse(v)))),
              ),
              SetRow(
                phone: phone,
                title: t.setTestFailsafe,
                desc: t.setTestFailsafeDesc,
                child: KButton(
                  t.runTest,
                  size: KSize.sm,
                  variant: KButtonVariant.secondary,
                  onPressed: d.linkLost || !d.hasDevice
                      ? null
                      : () {
                          d.dropLink();
                          go('live');
                        },
                ),
              ),
            ]),
            SizedBox(height: phone ? 20 : 32),
            section('Recording', [
              SetRow(
                phone: phone,
                title: t.setRecordVideo,
                desc: t.setRecordVideoDesc,
                child: KSwitch(checked: st.recordVideo, onChanged: (v) => d.updateSettings((s) => s.recordVideo = v)),
              ),
              if (st.recordVideo)
                SetRow(
                  phone: phone,
                  title: t.setVideoFps,
                  desc: t.setVideoFpsDesc,
                  child: fitSeg(
                    Seg(items: const ['5', '10', '15', '30'], value: '${st.videoFps}', onChanged: (v) => d.updateSettings((s) => s.videoFps = int.parse(v))),
                  ),
                ),
            ]),
            SizedBox(height: phone ? 20 : 32),
            section('Alerts', [
              SetRow(
                phone: phone,
                title: t.setAlertSound,
                desc: t.setAlertSoundDesc,
                child: KSwitch(checked: d.alertPrefs.sound, onChanged: (v) => d.updateAlerts((p) => p.sound = v)),
              ),
              for (final r in alertRules)
                SetRow(
                  phone: phone,
                  title: r.label,
                  desc: [r.desc, if (r.kinds != null) t.kindsOnly(r.kinds!.map((k) => k.label).join(', '))].join(' '),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(child: MonoLabel(r.below ? t.below : t.above, maxLines: 1)),
                      const SizedBox(width: 10),
                      SizedBox(width: 84, child: _LimitField(d, r, key: ValueKey('${r.id} ${u.imperial}'))),
                      const SizedBox(width: 8),
                      SizedBox(width: 32, child: MonoLabel(u.convertUnit(r.unit).unit)),
                      const SizedBox(width: 12),
                      KSwitch(checked: d.alertPrefs.isOn(r), onChanged: (v) => d.updateAlerts((p) => p.on[r.id] = v)),
                    ],
                  ),
                ),
            ]),
            SizedBox(height: phone ? 20 : 32),
            section('Map', [
              SetRow(
                phone: phone,
                title: t.setMapTiles,
                desc: t.setMapTilesDesc,
                // Five choices: on a small phone they shrink to the width.
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Seg(
                    small: phone,
                    items: const ['DARK', 'OUTDOORS', 'SATELLITE', 'CUSTOM', 'NONE'],
                    labels: {'DARK': t.mapDark, 'OUTDOORS': t.mapOutdoors, 'SATELLITE': t.mapSatellite, 'CUSTOM': t.mapCustom, 'NONE': t.mapNone},
                    value: st.mapTiles.toUpperCase(),
                    onChanged: (v) => d.updateSettings((s) => s.mapTiles = v.toLowerCase()),
                  ),
                ),
              ),
              if (tilesProblem(st) != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: KNotice(tone: Tone.warning, child: Text(tilesProblem(st)!)),
                ),
              if (st.mapTiles != 'custom' && st.mapTiles != 'none')
                SetRow(
                  phone: phone,
                  title: t.setMapboxToken,
                  desc: t.setMapboxTokenDesc,
                  child: SizedBox(
                    width: phone ? double.infinity : 320,
                    child: _TextSetting(d, get: (s) => s.mapboxToken, set: (s, v) => s.mapboxToken = v.trim(), placeholder: 'pk.…'),
                  ),
                ),
              if (st.mapTiles == 'custom')
                SetRow(
                  phone: phone,
                  title: t.setTileUrl,
                  desc: t.setTileUrlDesc('{z}', '{x}', '{y}'),
                  child: SizedBox(
                    width: phone ? double.infinity : 320,
                    child: _TextSetting(d, get: (s) => s.mapUrl, set: (s, v) => s.mapUrl = v, placeholder: 'https://…/{z}/{x}/{y}.png'),
                  ),
                ),
              if (st.mapTiles == 'custom')
                SetRow(
                  phone: phone,
                  title: t.setAttribution,
                  desc: t.setAttributionDesc,
                  child: SizedBox(
                    width: phone ? double.infinity : 320,
                    child: _TextSetting(d, get: (s) => s.mapAttribution, set: (s, v) => s.mapAttribution = v, placeholder: '© ${t.provider}'),
                  ),
                ),
            ]),
            SizedBox(height: phone ? 20 : 32),
            section('Pairing', [
              SetRow(
                phone: phone,
                title: t.setGuides,
                desc: t.setGuidesDesc,
                child: KButton(
                  t.open,
                  size: KSize.sm,
                  variant: KButtonVariant.ghost,
                  iconRight: const KIcon('arrow-right', size: 14),
                  onPressed: () => go('guides'),
                ),
              ),
              SetRow(
                phone: phone,
                title: t.pairedDevices,
                desc: d.devices.map((x) => x.name).join(', '),
                child: KButton(
                  t.manage,
                  size: KSize.sm,
                  variant: KButtonVariant.ghost,
                  iconRight: const KIcon('arrow-right', size: 14),
                  onPressed: () => go('devices'),
                ),
              ),
            ]),
            SizedBox(height: phone ? 20 : 32),
            section('AI assistants (MCP)', [AssistantsSection(d, phone: phone)]),
            SizedBox(height: phone ? 20 : 32),
            section('Scripts', [
              for (final h in d.scripts.hosts)
                SetRow(
                  phone: phone,
                  title: h.name,
                  desc: '${t.scriptHostAt('${h.address}${h.port == hostPort ? '' : ':${h.port}'}')}${h.python.isEmpty ? '' : ' · Python ${h.python}'}',
                  child: KButton(t.forget, size: KSize.sm, variant: KButtonVariant.ghost, onPressed: () => d.scripts.forgetHost(h)),
                ),
              SetRow(
                phone: phone,
                title: t.setScriptHosts,
                desc: phone ? t.setScriptHostsDescPhone : t.setScriptHostsDesc,
                child: KButton(t.add, size: KSize.sm, variant: KButtonVariant.secondary, onPressed: () => showAddHostDialog(context, d)),
              ),
              if (ScriptHub.canRunHere)
                SetRow(
                  phone: phone,
                  title: t.setBeHost,
                  desc: d.scripts.hostService == null
                      ? t.setBeHostDesc
                      : '${t.setBeHostCode(d.scripts.hostCode ?? '…')}${d.scripts.hostLog.isEmpty ? '' : '\n${d.scripts.hostLog.last}'}',
                  child: KSwitch(
                    checked: d.scripts.hostService != null,
                    onChanged: (v) async {
                      if (!v) return d.scripts.stopHostService();
                      if (d.scripts.pythons == null) await d.scripts.refreshPythons(near: await ScriptLibrary.defaultDir());
                      final py = d.scripts.pythons?.where((p) => p.hasPackage).firstOrNull?.path;
                      if (py != null) await d.scripts.startHostService(py);
                    },
                  ),
                ),
            ]),
            SizedBox(height: phone ? 20 : 32),
            section('Updates', [UpdatesSection(d: d, phone: phone)]),
          ],
        ),
      ),
    );
    if (!aside) return page;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _aside(),
        Expanded(child: page),
      ],
    );
  }
}

class _TextSetting extends StatefulWidget {
  const _TextSetting(this.d, {required this.get, required this.set, required this.placeholder});
  final Dash d;
  final String Function(Settings) get;
  final void Function(Settings, String) set;
  final String placeholder;
  @override
  State<_TextSetting> createState() => _TextSettingState();
}

class _TextSettingState extends State<_TextSetting> {
  late final _c = TextEditingController(text: widget.get(widget.d.settings));
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => KInput(
    controller: _c,
    placeholder: widget.placeholder,
    height: 40,
    style: KText.bodySm,
    onChanged: (v) => widget.d.updateSettings((s) => widget.set(s, v.trim())),
  );
}

class _LimitField extends StatefulWidget {
  const _LimitField(this.d, this.r, {super.key});
  final Dash d;
  final AlertRule r;
  @override
  State<_LimitField> createState() => _LimitFieldState();
}

class _LimitFieldState extends State<_LimitField> {
  // Limits are kept metric; typed and shown in the units shown.
  late final _conv = u.convertUnit(widget.r.unit);
  late final _c = TextEditingController(text: _fmt(widget.d.alertPrefs.limitOf(widget.r)));

  String _fmt(double metric) {
    final v = double.parse(_conv.shown(metric).toStringAsFixed(2));
    return v == v.roundToDouble() ? v.toStringAsFixed(0) : '$v';
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => KInput(
    controller: _c,
    placeholder: _fmt(widget.r.def),
    height: 36,
    style: KText.mono(13),
    keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
    onChanged: (v) {
      final x = double.tryParse(v.trim().replaceAll(',', '.'));
      widget.d.updateAlerts((p) => x == null ? p.limit.remove(widget.r.id) : p.limit[widget.r.id] = _conv.metric(x));
    },
  );
}
