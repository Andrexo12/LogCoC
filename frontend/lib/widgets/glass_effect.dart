import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class GlassEffect extends StatelessWidget {
  final Widget child;
  final double sigmaX;
  final double sigmaY;
  final bool enabled;

  const GlassEffect({
    super.key,
    required this.child,
    this.sigmaX = 10.0,
    this.sigmaY = 10.0,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!enabled || kIsWeb) {
      return child;
    }
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: sigmaX, sigmaY: sigmaY),
      child: child,
    );
  }
}
