import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/dash.dart';
import '../mcp/mcp_server.dart';
import '../scripts/script_hub.dart';
import '../theme/tokens.dart';
import '../ui/components.dart';

/// Turns the network side on or off: phones only take assistants from the network.
Future<void> applyMcpListening(Dash d) async {
  final m = d.mcp;
  if (m.enabled && (m.lan || !ScriptHub.canRunHere)) await d.scripts.start(lan: true);
}

/// Settings > AI assistants.
class AssistantsSection extends StatefulWidget {
  const AssistantsSection(this.d, {super.key, required this.phone});
  final Dash d;
  final bool phone;
  @override
  State<AssistantsSection> createState() => _AssistantsSectionState();
}

class _AssistantsSectionState extends State<AssistantsSection> {
  String client = 'Claude Code';
  String? ip;

  @override
  void initState() {
    super.initState();
    NetworkInterface.list(type: InternetAddressType.IPv4).then((l) {
      final a = l.expand((i) => i.addresses).where((a) => !a.isLoopback).firstOrNull;
      if (mounted) setState(() => ip = a?.address);
    });
  }

  Widget _row(String title, String desc, Widget child) {
    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: KText.bodyMd),
        const SizedBox(height: 6),
        Text(desc, style: KText.bodySm.copyWith(color: K.textMuted)),
      ],
    );
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: K.borderHairline))),
      child: widget.phone
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

  Widget _snippet(String s) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: K.surfaceSunken,
      border: Border.all(color: K.borderHairline),
      borderRadius: BorderRadius.circular(K.radiusCard),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: SelectableText(s, style: KText.mono(12, color: K.textSecondary, height: 1.6, w: FontWeight.w400))),
        const SizedBox(width: 12),
        KIconButton('copy', label: 'Copy', size: KSize.sm, variant: KIconButtonVariant.bare, onPressed: () => Clipboard.setData(ClipboardData(text: s))),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final d = widget.d, m = d.mcp, port = d.scripts.port ?? scriptApiPort;
    final local = ScriptHub.canRunHere;
    final url = local ? 'http://127.0.0.1:$port/mcp' : 'http://${ip ?? '<this device>'}:$port/mcp';
    final netUrl = 'http://${ip ?? '<address>'}:$port/mcp';
    final bridge = mcpBridgePath();
    final snippets = <String, String>{
      if (local) ...{
        'Claude Code': 'claude mcp add --transport http koebelt-dash $url',
        'Claude Desktop': bridge == null
            ? '{"mcpServers": {"koebelt-dash": {"command": "npx", "args": ["mcp-remote", "$url"]}}}'
            : '{"mcpServers": {"koebelt-dash": {"command": "${bridge.replaceAll(r'\', r'\\')}"}}}',
        'Cursor': '{"mcpServers": {"koebelt-dash": {"url": "$url"}}}',
        'Other': url,
      } else ...{
        'Claude Code': 'claude mcp add --transport http koebelt-dash $netUrl --header "Authorization: Bearer ${m.lanToken}"',
        'Other': '$netUrl\nAuthorization: Bearer ${m.lanToken}',
      },
    };
    if (!snippets.containsKey(client)) client = snippets.keys.first;
    final c = m.connected;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _row(
          'Let assistants use koebelt dash',
          'Claude, Cursor and other MCP clients can read the docs, write scripts, use the app and, with your approval, act on devices. dash itself sends nothing to any AI service; the assistant you connect talks to its own provider.',
          KSwitch(
            checked: m.enabled,
            onChanged: (v) async {
              m.enabled = v;
              if (!v) m.disconnectAll();
              m.save();
              await applyMcpListening(d);
              d.emit();
            },
          ),
        ),
        if (m.enabled) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Connect a client', style: KText.bodyMd),
                const SizedBox(height: 6),
                Text(
                  local ? 'Paste this into the assistant’s setup.' : 'Assistants run on a computer: they reach this ${widget.phone ? 'phone' : 'tablet'} over the network, with its token.',
                  style: KText.bodySm.copyWith(color: K.textMuted),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: KTabs(items: snippets.keys.toList(), value: client, onChanged: (v) => setState(() => client = v)),
                ),
                const SizedBox(height: 12),
                _snippet(snippets[client]!),
              ],
            ),
          ),
          _row(
            'Connected now',
            c == null ? 'No assistant in the last ten minutes.' : '${c.client} · ${c.actions} action${c.actions == 1 ? '' : 's'}',
            Wrap(
              spacing: 8,
              children: [
                KButton('Activity', size: KSize.sm, variant: KButtonVariant.secondary, onPressed: () => showActivity(context, d)),
                if (c != null) KButton('Disconnect', size: KSize.sm, variant: KButtonVariant.ghost, onPressed: m.disconnectAll),
              ],
            ),
          ),
          _row(
            'Allowed without asking',
            m.allowed.isEmpty
                ? 'Simulated devices and replays never ask. On real hardware, every action asks unless you allow it for the session. Arming and take-off always ask.'
                : 'For this session: ${m.allowed.map((a) => a.split(':').first).toSet().join(', ')}. Arming and take-off always ask.',
            KButton(
              'Reset',
              size: KSize.sm,
              variant: KButtonVariant.secondary,
              onPressed: m.allowed.isEmpty
                  ? null
                  : () {
                      m.allowed.clear();
                      d.emit();
                    },
            ),
          ),
          if (local)
            _row(
              'From this network',
              m.lan ? 'Assistants on other computers: $netUrl with the token ${m.lanToken.substring(0, 8)}… (copy it from the Other tab).' : 'Let an assistant on another computer use this dash, with a token.',
              KSwitch(
                checked: m.lan,
                onChanged: (v) async {
                  m.lan = v;
                  m.save();
                  await applyMcpListening(d);
                  if (v) setState(() => client = 'Other');
                  d.emit();
                },
              ),
            ),
        ],
      ],
    );
  }
}

/// The stdio bridge shipped inside the app, for clients that start a
/// command (Claude Desktop); null where it is not bundled.
String? mcpBridgePath() {
  final exe = File(Platform.resolvedExecutable);
  final candidates = [
    if (Platform.isMacOS) '${exe.parent.parent.path}/Resources/koebelt-dash-mcp',
    if (Platform.isWindows) '${exe.parent.path}\\koebelt-dash-mcp.exe',
    if (Platform.isLinux) '${exe.parent.path}/koebelt-dash-mcp',
  ];
  return candidates.where((p) => File(p).existsSync()).firstOrNull;
}

/// What assistants did, newest first.
Future<void> showActivity(BuildContext context, Dash d) => showKDialog<void>(
  context,
  builder: (ctx) => ListenableBuilder(
    listenable: d,
    builder: (ctx, _) {
      String two(int n) => n.toString().padLeft(2, '0');
      final items = d.mcp.activity.reversed.take(100).toList();
      return KDialogPanel(
        title: 'Assistant activity',
        width: 640,
        onClose: () => Navigator.pop(ctx),
        children: [
          if (items.isEmpty) Text('Nothing yet.', style: KText.bodySm.copyWith(color: K.textMuted)),
          for (final e in items)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 70,
                  child: Text('${two(e.at.hour)}:${two(e.at.minute)}:${two(e.at.second)}', style: KText.mono(11, color: K.textFaint, height: 1.6)),
                ),
                SizedBox(width: 130, child: Text(e.tool, style: KText.mono(11, color: e.ok ? K.textPrimary : K.negative, height: 1.6))),
                Expanded(child: Text(e.summary, maxLines: 2, overflow: TextOverflow.ellipsis, style: KText.bodySm.copyWith(color: K.textSecondary, height: 1.4))),
              ],
            ),
        ],
      );
    },
  ),
);

/// In the header while an assistant is connected.
class AssistantChip extends StatelessWidget {
  const AssistantChip(this.d, {super.key, this.compact = false});
  final Dash d;
  final bool compact;
  @override
  Widget build(BuildContext context) {
    final c = d.mcp.enabled ? d.mcp.connected : null;
    if (c == null) return const SizedBox.shrink();
    return Pressable(
      onTap: () => showActivity(context, d),
      builder: (_, hover, _) => Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: hover ? K.limeA32 : K.surfaceAccentSoft,
          border: Border.all(color: K.limeA32),
          borderRadius: BorderRadius.circular(K.radiusPill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const PulseDot(color: K.accent, animate: false),
            const SizedBox(width: 8),
            Text(compact ? 'AI' : '${c.client} · ${c.actions} action${c.actions == 1 ? '' : 's'}'.toUpperCase(), style: KText.label(color: K.textAccent)),
          ],
        ),
      ),
    );
  }
}

/// The card an assistant's action on real hardware waits on.
class ApprovalCard extends StatefulWidget {
  const ApprovalCard(this.d, this.a, {super.key, this.width = 400});
  final Dash d;
  final Approval a;
  final double width;
  @override
  State<ApprovalCard> createState() => _ApprovalCardState();
}

class _ApprovalCardState extends State<ApprovalCard> {
  bool session = false;
  late final Timer _t = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));

  @override
  void dispose() {
    _t.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.a;
    final left = McpServer.approvalTimeout - DateTime.now().difference(a.at);
    return Container(
      width: widget.width,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: K.surfaceRaised,
        border: Border.all(color: K.accent),
        borderRadius: BorderRadius.circular(K.radiusCard),
        boxShadow: K.shadowOverlay,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              MonoLabel('${a.client} asks', color: K.textAccent),
              const Spacer(),
              Text('0:${left.inSeconds.clamp(0, 59).toString().padLeft(2, '0')}', style: KText.mono(12, color: K.textMuted)),
            ],
          ),
          const SizedBox(height: 10),
          Text(a.title, style: KText.headingXs),
          const SizedBox(height: 8),
          Text('${a.device} is real hardware.${a.detail.isEmpty ? '' : ' ${a.detail}'}', style: KText.bodySm.copyWith(color: K.textSecondary)),
          if (!a.always) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                KSwitch(checked: session, onChanged: (v) => setState(() => session = v)),
                const SizedBox(width: 12),
                Expanded(child: Text('Allow this kind of action on ${a.device} for this session', style: KText.bodySm.copyWith(color: K.textSecondary))),
              ],
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: KButton('Refuse', variant: KButtonVariant.secondary, fullWidth: true, onPressed: () => widget.d.mcp.answer(a, false)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: KButton('Approve', fullWidth: true, onPressed: () => widget.d.mcp.answer(a, true, forSession: session)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
