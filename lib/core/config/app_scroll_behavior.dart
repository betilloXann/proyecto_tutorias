import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

// This class enables scrolling on devices that don't have a touch screen.
// It allows scrolling with a mouse, trackpad, etc.
class AppScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
      };
}
