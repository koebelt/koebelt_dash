import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../core/dash.dart';
import '../core/model.dart';
import '../link/discovery.dart';
import '../link/radio.dart';
import '../link/serial_io.dart';
import '../theme/tokens.dart';
import '../ui/components.dart';
import '../ui/icons.dart';
import '../ui/mark.dart';

class DevicesScreen extends StatelessWidget {
  const DevicesScreen(this.d, {super.key, required this.w, required this.go});
  final Dash d;
  final double w;
  final ValueChanged<String> go;

  void _remove(BuildContext context, DeviceInfo dev) {
    showKDialog(
      context,
      builder: (ctx) => KDialogPanel(
        title: t.removeTitle(dev.name),
        width: 440,
        onClose: () => Navigator.pop(ctx),
        footer: [
          KButton(t.cancel, variant: KButtonVariant.ghost, onPressed: () => Navigator.pop(ctx)),
          KButton(
            t.removeDevice,
            variant: KButtonVariant.inverse,
            onPressed: () {
              d.removeDevice(dev);
              Navigator.pop(ctx);
            },
          ),
        ],
        children: [Text('${t.removeBody(dev.name)}${d.links.containsKey(dev.id) ? ' ${t.removeDisconnectFirst}' : ''}'), Text(t.removeKept)],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final phone = w < 600;
    final online = d.devices.where((x) => x.online).length;
    return SingleChildScrollView(
      padding: phone ? const EdgeInsets.all(16) : const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PageHead(
              phone: phone,
              eyebrow: '${d.hasDevice ? '' : '${t.notConnected} · '}${t.onlineOf(online, d.devices.length)}',
              title: t.navDevices,
              right: KButton(
                t.pairDevice,
                variant: KButtonVariant.secondary,
                iconLeft: const KIcon('plus', size: 16),
                onPressed: () => showPairDialog(context, d, go),
              ),
            ),
            SizedBox(height: phone ? 20 : 32),
            if (d.connectError != null) ...[
              KNotice(tone: Tone.negative, title: t.connectFailed, child: Text(d.connectError!)),
              SizedBox(height: phone ? 20 : 32),
            ],
            hairline,
            for (final dev in d.devices) _row(context, dev, phone),
            if (d.devices.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 32),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: K.borderHairline)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.noPairedDevicesShort, style: KText.bodyMd),
                    const SizedBox(height: 12),
                    Text(t.devicesEmptyHint, style: KText.bodySm.copyWith(color: K.textMuted)),
                    const SizedBox(height: 12),
                    KButton(
                      t.quickstart,
                      size: KSize.sm,
                      variant: KButtonVariant.ghost,
                      iconRight: const KIcon('arrow-right', size: 14),
                      onPressed: () => go('guides'),
                    ),
                  ],
                ),
              ),
            SizedBox(height: phone ? 20 : 32),
            MonoLabel(t.devicesSeveral, height: 1.7),
          ],
        ),
      ),
    );
  }

  Widget _row(BuildContext context, DeviceInfo dev, bool phone) {
    final linked = d.links[dev.id], act = dev.id == d.deviceId && d.replay == null, off = !dev.online;
    final bat = linked != null ? linked.tel.battery.round() : dev.battery;
    final name = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(dev.name, style: KText.headingXs),
            if (act) KTag(t.fleetActive, tone: TagTone.accent) else if (linked != null) KTag(t.connected, tone: TagTone.info),
            if (dev.simulated) const SimTag() else KTag(dev.transport.label, height: 22),
            if (dev.proto != 'koebelt') KTag(_PairDialogState._protoLabel(dev.proto), tone: TagTone.info, height: 22),
          ],
        ),
        const SizedBox(height: 8),
        MonoLabel('${dev.kind.label} · ${dev.model.isEmpty ? dev.via : dev.model}', maxLines: 2, height: 1.3),
      ],
    );
    final actions = Row(
      mainAxisAlignment: MainAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (phone) ...[KBadge(off ? t.fleetOff : '$bat%', tone: off ? Tone.negative : Tone.positive), const SizedBox(width: 8)],
        if (linked != null) ...[
          KButton(
            t.disconnect,
            size: KSize.sm,
            variant: KButtonVariant.ghost,
            onPressed: () => d.disconnect(id: dev.id),
          ),
          if (!phone) ...[
            const SizedBox(width: 8),
            act
                ? KButton(t.open, size: KSize.sm, variant: KButtonVariant.secondary, onPressed: () => go('live'))
                : KButton(t.show, size: KSize.sm, variant: KButtonVariant.secondary, onPressed: () => d.focusDevice(dev.id)),
          ],
        ] else if (d.connecting == dev.id)
          Row(mainAxisSize: MainAxisSize.min, children: [const MarkMotion(MarkLoop.loading, size: 28), const SizedBox(width: 10), MonoLabel(t.connecting)])
        else
          KButton(t.connect, size: KSize.sm, variant: KButtonVariant.secondary, onPressed: off || d.connecting != null ? null : () => d.connect(dev.id)),
        const SizedBox(width: 8),
        KIconButton('trash', label: t.removeName(dev.name), size: KSize.sm, variant: KIconButtonVariant.bare, onPressed: () => _remove(context, dev)),
      ],
    );
    return Container(
      padding: EdgeInsets.symmetric(vertical: phone ? 16 : 20),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: K.borderHairline)),
      ),
      // On a phone the name gets the width, the buttons a line below.
      child: phone
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                name,
                const SizedBox(height: 12),
                Align(alignment: Alignment.centerLeft, child: actions),
              ],
            )
          : Row(
              children: [
                Expanded(flex: 13, child: name),
                const SizedBox(width: 24),
                Expanded(flex: 14, child: Wrap(spacing: 6, runSpacing: 6, children: [for (final s in dev.sensors) KTag(s)])),
                const SizedBox(width: 24),
                SizedBox(
                  width: 90,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      KBadge(off ? t.offline : t.online, tone: off ? Tone.negative : Tone.positive),
                      const SizedBox(height: 6),
                      MonoLabel('${t.batShort} $bat%', color: bat < 20 ? K.negative : K.textSecondary),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                ConstrainedBox(constraints: const BoxConstraints(minWidth: 250), child: actions),
              ],
            ),
    );
  }
}

void showPairDialog(BuildContext context, Dash d, ValueChanged<String> go, {bool simulated = false, bool radio = false}) {
  showKDialog(
    context,
    builder: (ctx) => _PairDialog(d: d, go: go, simulated: simulated, radio: radio),
  );
}

class _PairDialog extends StatefulWidget {
  const _PairDialog({required this.d, required this.go, this.simulated = false, this.radio = false});
  final Dash d;
  final bool simulated, radio;
  final ValueChanged<String> go;
  @override
  State<_PairDialog> createState() => _PairDialogState();
}

class _PairDialogState extends State<_PairDialog> {
  bool manual = false;
  String? error;
  final _name = TextEditingController(text: t.myRobot), _host = TextEditingController();
  DeviceKind _kind = DeviceKind.rover;
  String _proto = 'koebelt';
  late String tab = widget.simulated
      ? 'Simulated'
      : widget.radio
      ? 'Radio'
      : 'Nearby';
  final Set<String> _added = {};

  // radio tab
  RadioModule _module = radioModules.first;
  String? _port;
  List<String> _ports = const [];
  final _baud = TextEditingController(text: '${radioModules.first.baud}');
  bool _listening = false;
  Found? _heard;
  String? _radioNote;

  @override
  void initState() {
    super.initState();
    widget.d.startScan();
    _refreshPorts();
  }

  @override
  void dispose() {
    widget.d.stopScan();
    _name.dispose();
    _host.dispose();
    _baud.dispose();
    super.dispose();
  }

  void _refreshPorts() {
    _ports = usbPorts();
    if (_port == null || !_ports.contains(_port)) {
      // Prefer a port whose USB name looks like a radio.
      _port = _ports.where((p) => radioForUsb(describePort(p)) != null).firstOrNull ?? _ports.firstOrNull;
      final r = _port == null ? null : radioForUsb(describePort(_port!));
      if (r != null) _pick(r);
    }
  }

  void _pick(RadioModule m) {
    _module = m;
    _baud.text = '${m.baud}';
    _heard = null;
    _radioNote = null;
  }

  int get _baudValue => int.tryParse(_baud.text.trim()) ?? _module.baud;

  Future<void> _listen() async {
    final p = _port;
    if (p == null) return;
    setState(() {
      _listening = true;
      _heard = null;
      _radioNote = null;
    });
    final f = await probePort(p, _module, baud: _baudValue);
    if (!mounted) return;
    setState(() {
      _listening = false;
      _heard = f;
      _radioNote = f == null ? t.radioNothingHeard(p.split('/').last, _baudValue) : null;
    });
  }

  Future<void> _addRadio() async {
    final p = _port;
    if (p == null) return;
    final f = _heard;
    if (f != null && (f.pair != null || !f.native)) {
      // In pairing mode (it gets a key over the radio), or a MAVLink vehicle.
      final e = await widget.d.pair(f);
      if (!mounted) return;
      if (e != null) {
        setState(() => error = e);
        return;
      }
      final dev = widget.d.devices.where((x) => x.id == f.id).firstOrNull;
      if (dev != null && _baudValue != _module.baud) dev.baud = _baudValue;
      if (dev != null) unawaited(widget.d.connect(dev.id));
    } else {
      widget.d.addRadio(p, _module, baud: _baudValue, name: f?.name, kind: f == null ? DeviceKind.generic : DeviceKind.parse(f.kind));
    }
    if (mounted) Navigator.pop(context);
  }

  /// One tap: add the device (pairing it when it shows our code) and
  /// connect to it.
  Future<void> _pair(Found f) async {
    final e = await widget.d.pair(f);
    if (!mounted) return;
    if (e != null) {
      setState(() => error = e);
      return;
    }
    unawaited(widget.d.connect(f.id));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.d,
      builder: (context, _) {
        final found = widget.d.found.values.toList();
        return KDialogPanel(
          title: t.pairTitle,
          width: 480,
          onClose: () => Navigator.pop(context),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: KTabs(
                items: const ['Nearby', 'Radio', 'Simulated'],
                labels: {'Nearby': t.pairNearby, 'Radio': t.pairRadio, 'Simulated': t.pairSimulated},
                value: tab,
                onChanged: (v) => setState(() => tab = v),
              ),
            ),
            if (tab == 'Simulated')
              ..._simulated(context)
            else if (tab == 'Radio')
              ..._radio(context, found.where((f) => f.transport == 'radio').toList())
            else
              ..._nearby(context, [
                for (final c in const ['USB', 'Wi-Fi', 'Bluetooth']) ...found.where((f) => f.transport != 'radio' && _categoryOf(f) == c),
                ...found.where((f) => f.transport != 'radio' && !const ['USB', 'Wi-Fi', 'Bluetooth'].contains(_categoryOf(f))),
              ]),
          ],
        );
      },
    );
  }

  List<Widget> _simulated(BuildContext context) {
    final d = widget.d;
    return [
      Text(t.pairSimulatedIntro),
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          hairline,
          for (final tpl in simTemplates())
            Container(
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
                        Row(
                          children: [
                            Flexible(
                              child: Text(tpl.kind.label, style: KText.bodyMd, maxLines: 1, overflow: TextOverflow.ellipsis),
                            ),
                            const SizedBox(width: 8),
                            const SimTag(height: 20),
                          ],
                        ),
                        const SizedBox(height: 6),
                        MonoLabel(tpl.model, maxLines: 1),
                        const SizedBox(height: 4),
                        MonoLabel(tpl.sensors.join(' · '), size: 9, maxLines: 2, height: 1.4),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (_added.contains(tpl.id)) ...[MonoLabel(t.added, color: K.textAccent), const SizedBox(width: 8)],
                  KButton(
                    _added.contains(tpl.id) ? t.addAnother : t.add,
                    size: KSize.sm,
                    variant: _added.contains(tpl.id) ? KButtonVariant.ghost : KButtonVariant.primary,
                    onPressed: () {
                      d.addSimulated(tpl);
                      setState(() => _added.add(tpl.id));
                    },
                  ),
                ],
              ),
            ),
        ],
      ),
    ];
  }

  static String _protoLabel(String p) => switch (p) {
    'mavlink' => 'MAVLink',
    'msp' => 'MSP',
    'tello' => 'Tello',
    _ => p,
  };

  static String _categoryOf(Found f) => f.module == 'btserial' ? 'Bluetooth' : _category(f.transport);

  static String _category(String transport) => switch (transport) {
    'udp' => 'Wi-Fi',
    'ble' => 'Bluetooth',
    'serial' => 'USB',
    _ => transport,
  };

  List<Widget> _radio(BuildContext context, List<Found> recognised) {
    final m = _module;
    final rates = m.telemetryOnly ? t.radioRatesTlm(m.tlmHz) : t.radioRates(m.tlmHz, m.ctlHz);
    Widget section(String label) => MonoLabel(label, color: K.textSecondary);
    if (!serialSupported) {
      return [Text(t.radioIntro), KNotice(tone: Tone.warning, title: t.radioNoSerial, child: Text(t.radioNoSerialBody))];
    }
    return [
      Text('${t.radioIntro} ${t.radioIntroMore}'),
      section(t.pairRadio),
      Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final r in radioModules)
            Pressable(
              onTap: () => setState(() => _pick(r)),
              builder: (_, _, _) => KTag(r.name, tone: r == m ? TagTone.accent : TagTone.neutral),
            ),
        ],
      ),
      Text(m.desc, style: KText.bodySm.copyWith(color: K.textMuted)),
      MonoLabel(rates, color: m.telemetryOnly ? K.warning : K.textMuted),
      if (m.bridge) KNotice(tone: Tone.info, child: Text(t.radioLora)),
      Row(
        children: [
          Expanded(child: section(t.usbPort)),
          KButton(t.refresh, size: KSize.sm, variant: KButtonVariant.ghost, onPressed: () => setState(_refreshPorts)),
        ],
      ),
      if (_ports.isEmpty)
        MonoLabel(t.noSerialPorts)
      else
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final p in _ports)
              Pressable(
                onTap: () => setState(() {
                  _port = p;
                  _heard = null;
                  _radioNote = null;
                }),
                builder: (_, h, _) {
                  final sel = p == _port, known = radioForUsb(describePort(p));
                  final hit = recognised.any((f) => f.address == p);
                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    margin: const EdgeInsets.only(bottom: 6),
                    decoration: BoxDecoration(
                      color: sel ? K.surfaceAccentSoft : (h ? K.whiteA06 : Colors.transparent),
                      border: Border.all(color: sel ? K.limeA32 : K.borderHairline),
                      borderRadius: BorderRadius.circular(K.radiusCard),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(describePort(p), style: KText.bodySm),
                              const SizedBox(height: 4),
                              MonoLabel(p, size: 9),
                            ],
                          ),
                        ),
                        if (known != null || hit) KTag(known?.name ?? t.pairRadio, tone: TagTone.info, height: 22),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      section(t.baudRate),
      KInput(controller: _baud, placeholder: '${m.baud}', height: 40, style: KText.bodySm),
      if (_heard != null)
        KNotice(
          tone: Tone.positive,
          title: t.heard(_heard!.name),
          child: Text(
            '${DeviceKind.parse(_heard!.kind).label}${_heard!.model.isEmpty ? '' : ' · ${_heard!.model}'}. ${!_heard!.native
                ? t.heardMavlink
                : _heard!.pair != null
                ? t.heardPairing
                : t.heardNoPairing}',
          ),
        ),
      if (_radioNote != null) KNotice(tone: Tone.warning, child: Text(_radioNote!)),
      if (error != null) KNotice(tone: Tone.negative, child: Text(error!)),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          if (_listening)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const MarkMotion(MarkLoop.searching, size: 36, gap: K.surfaceRaised),
                  const SizedBox(width: 10),
                  MonoLabel(t.listening),
                ],
              ),
            )
          else
            KButton(t.listenForDevice, size: KSize.sm, variant: KButtonVariant.secondary, onPressed: _port == null ? null : _listen),
          KButton(_heard?.pair != null ? t.pairName(_heard!.name) : t.addRadioLink, size: KSize.sm, onPressed: _port == null || _listening ? null : _addRadio),
        ],
      ),
    ];
  }

  List<Widget> _nearby(BuildContext context, List<Found> found) {
    return [
      Text(t.pairNearbyIntro),
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          hairline,
          for (final (i, f) in found.indexed) ...[
            if (i == 0 || _categoryOf(found[i - 1]) != _categoryOf(f))
              Padding(
                padding: const EdgeInsets.only(top: 14),
                child: MonoLabel(_categoryOf(f), color: K.textSecondary),
              ),
            Container(
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
                        Row(
                          children: [
                            Flexible(
                              child: Text(f.name, style: KText.bodyMd, maxLines: 1, overflow: TextOverflow.ellipsis),
                            ),
                            if (!f.native) ...[const SizedBox(width: 8), KTag(_protoLabel(f.proto), tone: TagTone.info, height: 20)],
                          ],
                        ),
                        const SizedBox(height: 6),
                        MonoLabel([DeviceKind.parse(f.kind).label, if (f.model.isNotEmpty) f.model, f.via].join(' · '), maxLines: 2, height: 1.4),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  KButton(f.native && f.pair != null ? 'Pair' : 'Connect', size: KSize.sm, onPressed: () => _pair(f)),
                ],
              ),
            ),
          ],
          // Discovery runs for as long as the dialog is open.
          Padding(
            key: const ValueKey('scanning'),
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              children: [
                const MarkMotion(MarkLoop.searching, size: 36, gap: K.surfaceRaised),
                const SizedBox(width: 12),
                Expanded(child: MonoLabel(found.isEmpty ? t.scanning : t.stillScanning, maxLines: 2, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
      if (error != null) KNotice(tone: Tone.negative, child: Text(error!)),
      if (manual) ...[
        MonoLabel(t.addByIp),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final (p, l) in const [('koebelt', 'koebelt/link'), ('mavlink', 'MAVLink'), ('tello', 'Tello')])
              Pressable(
                onTap: () => setState(() {
                  _proto = p;
                  if (p == 'tello') _host.text = '192.168.10.1';
                  if (p != 'koebelt') _kind = DeviceKind.drone;
                }),
                builder: (_, _, _) => KTag(l, tone: p == _proto ? TagTone.accent : TagTone.neutral),
              ),
          ],
        ),
        KInput(controller: _name, placeholder: t.name, height: 40, style: KText.bodySm),
        KInput(controller: _host, placeholder: _proto == 'mavlink' ? '192.168.4.1 · 192.168.4.1:14555' : '192.168.1.42', height: 40, style: KText.bodySm),
        if (_proto == 'mavlink') MonoLabel(t.mavlinkPortNote, maxLines: 3, height: 1.5),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final k in DeviceKind.values)
              Pressable(
                onTap: () => setState(() => _kind = k),
                builder: (_, _, _) => KTag(k.label, tone: k == _kind ? TagTone.accent : TagTone.neutral),
              ),
          ],
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: KButton(
            t.addDevice,
            size: KSize.sm,
            onPressed: () {
              if (_host.text.trim().isEmpty) return;
              final dev = widget.d.addManual(_name.text.trim().isEmpty ? _host.text.trim() : _name.text.trim(), _host.text.trim(), _kind, proto: _proto);
              unawaited(widget.d.connect(dev.id));
              Navigator.pop(context);
            },
          ),
        ),
      ],
      Text.rich(
        TextSpan(
          children: [
            TextSpan(text: '${t.notShowingUp} '),
            WidgetSpan(
              child: _Link(t.openQuickstart, () {
                Navigator.pop(context);
                widget.go('guides');
              }),
            ),
            if (!manual) ...[TextSpan(text: ' ${t.orLower} '), WidgetSpan(child: _Link(t.addItByIp, () => setState(() => manual = true)))],
          ],
        ),
      ),
    ];
  }
}

class _Link extends StatelessWidget {
  const _Link(this.text, this.onTap);
  final String text;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Pressable(
    onTap: onTap,
    builder: (_, h, _) => Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: h ? K.accent : K.whiteA20)),
      ),
      child: Text(text, style: KText.bodySm.copyWith(color: h ? K.accent : K.textPrimary)),
    ),
  );
}
