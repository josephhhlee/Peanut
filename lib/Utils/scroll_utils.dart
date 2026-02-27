import 'package:flutter/material.dart';

class DisableScrollGlow extends StatelessWidget {
  final Widget child;
  const DisableScrollGlow({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ScrollConfiguration(
      behavior: _NoScrollGlow(),
      child: child,
    );
  }
}

class _NoScrollGlow extends ScrollBehavior {
  @override
  Widget buildViewportChrome(BuildContext context, Widget child, AxisDirection axisDirection) {
    return child;
  }
}
