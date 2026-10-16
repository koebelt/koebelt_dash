import 'dart:io';

import 'package:flutter/services.dart';

const _channel = MethodChannel('com.koebelt.dash/system');
bool? _immersive;

/// iPhone and iPad: dims the home indicator and keeps a first swipe from the
/// bottom edge in the app (KDashViewController in ios/Runner), for screens
/// whose controls reach the bottom edge. Other platforms ignore it.
void setImmersive(bool on) {
  if (!Platform.isIOS || _immersive == on) return;
  _immersive = on;
  _channel.invokeMethod<void>('setImmersive', on).catchError((Object _) {});
}
