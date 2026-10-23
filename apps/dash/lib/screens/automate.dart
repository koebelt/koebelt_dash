import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import '../ui/components.dart';
import '../ui/icons.dart';
import 'guides.dart';

/// What each Automate tab is for, in a line.
const automateBlurbs = {
  'program': 'Steps in order, no code. Devices that can store a sequence run it themselves, and keep going if the link drops.',
  'scripts': 'Python on a computer: logic, sensors, the camera, any package. A script can start a sequence too.',
};

/// Automate's two tabs, Sequences and Scripts, with what the one shown is
/// for and a link to the guide that compares them.
class AutomateTabs extends StatelessWidget {
  const AutomateTabs({super.key, required this.screen, required this.phone, required this.go});
  final String screen;
  final bool phone;
  final ValueChanged<String> go;

  @override
  Widget build(BuildContext context) {
    final tabs = KTabs(
      items: const ['Sequences', 'Scripts'],
      value: screen == 'scripts' ? 'Scripts' : 'Sequences',
      onChanged: (v) => go(v == 'Scripts' ? 'scripts' : 'program'),
    );
    final blurb = Text(automateBlurbs[screen] ?? '', style: KText.bodySm.copyWith(fontSize: 13, color: K.textMuted, height: 1.4));
    final link = Pressable(
      onTap: () {
        GuidesScreen.pending = 'sequence-or-script';
        go('guides');
      },
      builder: (_, h, _) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Sequence or script?', style: KText.bodySm.copyWith(fontSize: 13, color: h ? K.accentHover : K.textAccent)),
          const SizedBox(width: 4),
          KIcon('arrow-right', size: 14, color: h ? K.accentHover : K.textAccent),
        ],
      ),
    );
    return Padding(
      padding: EdgeInsets.fromLTRB(phone ? 16 : 32, 14, phone ? 16 : 32, 0),
      child: phone
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                tabs,
                const SizedBox(height: 8),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: '${automateBlurbs[screen] ?? ''} '),
                      WidgetSpan(alignment: PlaceholderAlignment.middle, child: link),
                    ],
                  ),
                  style: KText.bodySm.copyWith(fontSize: 13, color: K.textMuted, height: 1.4),
                ),
              ],
            )
          : Row(
              children: [
                tabs,
                const SizedBox(width: 24),
                Expanded(child: blurb),
                const SizedBox(width: 16),
                link,
              ],
            ),
    );
  }
}
