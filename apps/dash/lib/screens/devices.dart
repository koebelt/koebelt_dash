import 'package:flutter/material.dart';

import '../core/dash.dart';
import '../core/model.dart';
import '../link/discovery.dart';
import '../link/radio.dart';
import '../link/serial_io.dart';
import '../theme/tokens.dart';
import '../ui/components.dart';
import '../ui/icons.dart';

class DevicesScreen extends StatelessWidget {
  const DevicesScreen(this.d, {super.key, required this.w, required this.go});
  final Dash d;
  final double w;
  final ValueChanged<String> go;

  void _remove(BuildContext context, DeviceInfo dev) {
    showKDialog(
      context,
      builder: (ctx) => KDialogPanel(
        title: 'Remove ${dev.name}?',
        width: 440,
        onClose: () => Navigator.pop(ctx),
        footer: [
          KButton('Cancel', variant: KButtonVariant.ghost, onPressed: () => Navigator.pop(ctx)),
          KButton(
            'Remove device',
            variant: KButtonVariant.inverse,
            onPressed: () {
              d.removeDevice(dev);
              Navigator.pop(ctx);
            },
          ),
        ],
        children: [
          Text(
            'The pairing key, HUD layouts and parameter drafts for ${dev.name} are deleted from this app.${dev.id == d.deviceId ? ' It will be disconnected first.' : ''}',
          ),
          const Text('Recordings are kept. To use the device again, pair it with a new code.'),
        ],
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
              eyebrow: '${d.hasDevice ? '' : 'Not connected · '}$online of ${d.devices.length} online',
              title: 'Devices',
              right: KButton(
                'Pair device',
                variant: KButtonVariant.secondary,
                iconLeft: const KIcon('plus', size: 16),
                onPressed: () => showPairDialog(context, d, go),
              ),
            ),
            SizedBox(height: phone ? 20 : 32),
            if (d.connectError != null) ...[
              KNotice(tone: Tone.negative, title: 'Could not connect', child: Text(d.connectError!)),
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
                    Text('No paired devices', style: KText.bodyMd),
                    const SizedBox(height: 12),
                    Text('Pair a device, or follow the quickstart to add the library to your project.', style: KText.bodySm.copyWith(color: K.textMuted)),
                    const SizedBox(height: 12),
                    KButton(
                      'Quickstart',
                      size: KSize.sm,
                      variant: KButtonVariant.ghost,
                      iconRight: const KIcon('arrow-right', size: 14),
                      onPressed: () => go('guides'),
                    ),
                  ],
                ),
              ),
            SizedBox(height: phone ? 20 : 32),
            const MonoLabel('Switching device keeps the previous one in its current mode. Drones switch to hold.', height: 1.7),
          ],
        ),
      ),
    );
  }

  Widget _row(BuildContext context, DeviceInfo dev, bool phone) {
    final act = dev.id == d.deviceId && d.replay == null, off = !dev.online;
    final bat = act ? d.liveTel.battery.round() : dev.battery;
    final name = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(dev.name, style: KText.headingXs),
            if (act) const KTag('Active', tone: TagTone.accent),
            if (dev.simulated) const SimTag() else KTag(dev.transport.label, height: 22),
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
        if (phone) ...[KBadge(off ? 'Off' : '$bat%', tone: off ? Tone.negative : Tone.positive), const SizedBox(width: 8)],
        if (act) ...[
          KButton('Disconnect', size: KSize.sm, variant: KButtonVariant.ghost, onPressed: d.disconnect),
          if (!phone) ...[const SizedBox(width: 8), KButton('Open', size: KSize.sm, variant: KButtonVariant.secondary, onPressed: () => go('live'))],
        ] else if (d.connecting == dev.id)
          const Row(mainAxisSize: MainAxisSize.min, children: [ScanDot(), SizedBox(width: 10), MonoLabel('Connecting')])
        else
          KButton('Connect', size: KSize.sm, variant: KButtonVariant.secondary, onPressed: off || d.connecting != null ? null : () => d.connect(dev.id)),
        const SizedBox(width: 8),
        KIconButton('trash', label: 'Remove ${dev.name}', size: KSize.sm, variant: KIconButtonVariant.bare, onPressed: () => _remove(context, dev)),
      ],
    );
    return Container(
      padding: EdgeInsets.symmetric(vertical: phone ? 16 : 20),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: K.borderHairline)),
      ),
      child: phone
          ? Row(
              children: [
                Expanded(child: name),
                const SizedBox(width: 12),
                actions,
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
                      KBadge(off ? 'Offline' : 'Online', tone: off ? Tone.negative : Tone.positive),
                      const SizedBox(height: 6),
                      MonoLabel('BAT $bat%', color: bat < 20 ? K.negative : K.textSecondary),
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
  bool scanning = true, manual = false;
  String? error;
  final _name = TextEditingController(text: 'My robot'), _host = TextEditingController();
  DeviceKind _kind = DeviceKind.rover;
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
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (mounted) setState(() => scanning = false);
    });
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
      _radioNote = f == null
          ? 'Nothing heard on ${p.split('/').last} at $_baudValue baud. Check that the device is on, both radios use the same channel and air rate, and the baud rate matches. You can still add the link and connect later.'
          : null;
    });
  }

  Future<void> _addRadio() async {
    final p = _port;
    if (p == null) return;
    final f = _heard;
    if (f != null && f.pair != null) {
      // The device is in pairing mode: pair over the radio so it gets a key.
      final e = await widget.d.pair(f);
      if (!mounted) return;
      if (e != null) {
        setState(() => error = e);
        return;
      }
      final dev = widget.d.devices.where((x) => x.id == f.id).firstOrNull;
      if (dev != null && _baudValue != _module.baud) dev.baud = _baudValue;
    } else {
      widget.d.addRadio(p, _module, baud: _baudValue, name: f?.name, kind: f == null ? DeviceKind.generic : DeviceKind.parse(f.kind));
    }
    if (mounted) Navigator.pop(context);
  }

  Future<void> _pair(Found f) async {
    final e = await widget.d.pair(f);
    if (mounted) setState(() => error = e);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.d,
      builder: (context, _) {
        final found = widget.d.found.values.toList();
        return KDialogPanel(
          title: 'Pair a device',
          width: 480,
          onClose: () => Navigator.pop(context),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: KTabs(items: const ['Nearby', 'Radio', 'Simulated'], value: tab, onChanged: (v) => setState(() => tab = v)),
            ),
            if (tab == 'Simulated')
              ..._simulated(context)
            else if (tab == 'Radio')
              ..._radio(context, found.where((f) => f.transport == 'radio').toList())
            else
              ..._nearby(context, found.where((f) => f.transport != 'radio').toList()),
          ],
        );
      },
    );
  }

  List<Widget> _simulated(BuildContext context) {
    final d = widget.d;
    return [
      const Text(
        'Simulated devices run inside this app and speak the same protocol as real hardware. Add only the ones you need; each one is listed with a SIM tag.',
      ),
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          hairline,
          for (final t in simTemplates())
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
                            Text(t.kind.label, style: KText.bodyMd),
                            const SizedBox(width: 8),
                            const SimTag(height: 20),
                          ],
                        ),
                        const SizedBox(height: 6),
                        MonoLabel(t.model, maxLines: 1),
                        const SizedBox(height: 4),
                        MonoLabel(t.sensors.join(' · '), size: 9, maxLines: 2, height: 1.4),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (_added.contains(t.id)) ...[const MonoLabel('Added', color: K.textAccent), const SizedBox(width: 8)],
                  KButton(
                    _added.contains(t.id) ? 'Add another' : 'Add',
                    size: KSize.sm,
                    variant: _added.contains(t.id) ? KButtonVariant.ghost : KButtonVariant.primary,
                    onPressed: () {
                      d.addSimulated(t);
                      setState(() => _added.add(t.id));
                    },
                  ),
                ],
              ),
            ),
        ],
      ),
    ];
  }

  static String _category(String transport) => switch (transport) {
    'udp' => 'Wi-Fi',
    'ble' => 'Bluetooth',
    'serial' => 'USB',
    _ => transport,
  };

  List<Widget> _radio(BuildContext context, List<Found> recognised) {
    final m = _module;
    final rates = m.telemetryOnly ? 'Telemetry ${m.tlmHz} Hz · no control' : 'Telemetry ${m.tlmHz} Hz · control ${m.ctlHz} Hz';
    Widget section(String t) => MonoLabel(t, color: K.textSecondary);
    if (!serialSupported) {
      return [
        const Text('A radio link is a radio modem plugged into this computer or phone over USB, talking to a matching radio on the device.'),
        const KNotice(
          tone: Tone.warning,
          title: 'No USB serial on this platform',
          child: Text(
            'iOS apps cannot open USB serial adapters. Use the app on Android, macOS, Windows or Linux for radio links, or connect over Wi-Fi or Bluetooth.',
          ),
        ),
      ];
    }
    return [
      const Text(
        'A radio link is a radio modem plugged into this computer or phone over USB, talking to a matching radio on the device. To the app it is a serial port; the radio type sets the speed and how much it can carry.',
      ),
      section('Radio'),
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
      if (m.bridge)
        const KNotice(
          tone: Tone.info,
          child: Text(
            'LoRa modules are not USB devices on their own. Flash the ground-station sketch from the LoRa guide onto a second board with the radio, and plug that board in.',
          ),
        ),
      Row(
        children: [
          Expanded(child: section('USB port')),
          KButton('Refresh', size: KSize.sm, variant: KButtonVariant.ghost, onPressed: () => setState(_refreshPorts)),
        ],
      ),
      if (_ports.isEmpty)
        const MonoLabel('No serial ports found. Plug in the radio\'s USB adapter.')
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
                        if (known != null || hit) KTag(known?.name ?? 'Radio', tone: TagTone.info, height: 22),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      section('Baud rate'),
      KInput(controller: _baud, placeholder: '${m.baud}', height: 40, style: KText.bodySm),
      if (_heard != null)
        KNotice(
          tone: Tone.positive,
          title: 'Heard ${_heard!.name}',
          child: Text(
            '${DeviceKind.parse(_heard!.kind).label}${_heard!.model.isEmpty ? '' : ' · ${_heard!.model}'}. ${_heard!.pair != null ? 'It is in pairing mode and will get a key.' : 'It is not in pairing mode; it is added without a key.'}',
          ),
        ),
      if (_radioNote != null) KNotice(tone: Tone.warning, child: Text(_radioNote!)),
      if (error != null) KNotice(tone: Tone.negative, child: Text(error!)),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          if (_listening)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Row(mainAxisSize: MainAxisSize.min, children: [ScanDot(), SizedBox(width: 10), MonoLabel('Listening')]),
            )
          else
            KButton('Listen for device', size: KSize.sm, variant: KButtonVariant.secondary, onPressed: _port == null ? null : _listen),
          KButton(_heard?.pair != null ? 'Pair ${_heard!.name}' : 'Add radio link', size: KSize.sm, onPressed: _port == null || _listening ? null : _addRadio),
        ],
      ),
    ];
  }

  List<Widget> _nearby(BuildContext context, List<Found> found) {
    return [
      const Text('Power on the device and hold its pair button for three seconds.'),
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          hairline,
          if (scanning && found.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Row(children: [ScanDot(), SizedBox(width: 12), MonoLabel('Scanning BLE and local network…')]),
            )
          else if (found.isEmpty)
            const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: MonoLabel('No new devices found'))
          else
            for (final (i, f) in found.indexed) ...[
              if (i == 0 || found[i - 1].transport != f.transport)
                Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: MonoLabel(_category(f.transport), color: K.textSecondary),
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
                          Text(f.name, style: KText.bodyMd),
                          const SizedBox(height: 6),
                          MonoLabel('${DeviceKind.parse(f.kind).label} · ${f.via}'),
                        ],
                      ),
                    ),
                    KButton('Pair', size: KSize.sm, onPressed: () => _pair(f)),
                  ],
                ),
              ),
            ],
        ],
      ),
      if (error != null) KNotice(tone: Tone.negative, child: Text(error!)),
      if (manual) ...[
        const MonoLabel('Add by IP address'),
        KInput(controller: _name, placeholder: 'Name', height: 40, style: KText.bodySm),
        KInput(controller: _host, placeholder: '192.168.1.42', height: 40, style: KText.bodySm),
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
            'Add device',
            size: KSize.sm,
            onPressed: () {
              if (_host.text.trim().isEmpty) return;
              widget.d.addManual(_name.text.trim().isEmpty ? _host.text.trim() : _name.text.trim(), _host.text.trim(), _kind);
              Navigator.pop(context);
            },
          ),
        ),
      ],
      Text.rich(
        TextSpan(
          children: [
            const TextSpan(text: 'Device not showing up? It needs the KoebeltLink library. '),
            WidgetSpan(
              child: _Link('Open the quickstart', () {
                Navigator.pop(context);
                widget.go('guides');
              }),
            ),
            if (!manual) ...[const TextSpan(text: ' or '), WidgetSpan(child: _Link('add it by IP address', () => setState(() => manual = true)))],
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
