import 'dart:math' show sqrt, max;
import 'dart:ui' show lerpDouble;
import 'package:flutter/material.dart';

Map<String?, int> _navigatorManagerPageMap = {};
ValueKey _createPageKey(String? name) {
  name = name ?? "";
  if (_navigatorManagerPageMap[name] != null) {
    _navigatorManagerPageMap[name] = _navigatorManagerPageMap[name]! + 1;
    name = '$name-${_navigatorManagerPageMap[name]}';
  } else {
    _navigatorManagerPageMap[name] = 0;
    name = '$name-${_navigatorManagerPageMap[name]}';
  }
  return ValueKey(name);
}

class PeanutPage extends Page {
  final String? pageName;
  final Widget? child;
  final bool maintainState;
  final bool fullscreenDialog;
  final bool isTransparent;
  final Widget Function(Animation<double> animation, Widget child)? transition;
  PeanutPage({
    this.pageName,
    this.child,
    this.maintainState = true,
    this.fullscreenDialog = false,
    this.transition,
    this.isTransparent = false,
  }) : super(key: _createPageKey(pageName));

  @override
  Route createRoute(BuildContext context) {
    if (transition != null) {
      return PageRouteBuilder(
        opaque: !isTransparent,
        settings: this,
        maintainState: maintainState,
        fullscreenDialog: fullscreenDialog,
        transitionDuration: const Duration(milliseconds: 200),
        reverseTransitionDuration: const Duration(milliseconds: 200),
        pageBuilder: (context, animation, secondaryAnimation) => child!,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return transition!(animation, child);
        },
      );
    } else {
      return PageRouteBuilder(
        opaque: !isTransparent,
        settings: this,
        maintainState: maintainState,
        fullscreenDialog: fullscreenDialog,
        pageBuilder: (context, animation, secondaryAnimation) => child!,
      );
    }
  }
}

@immutable
class CircularRevealClipper extends CustomClipper<Path> {
  final double fraction;
  final Alignment? centerAlignment;
  final Offset? centerOffset;
  final double? minRadius;
  final double? maxRadius;

  const CircularRevealClipper({
    required this.fraction,
    this.centerAlignment,
    this.centerOffset,
    this.minRadius,
    this.maxRadius,
  });

  @override
  Path getClip(Size size) {
    final Offset center = centerAlignment?.alongSize(size) ?? centerOffset ?? Offset(size.width / 2, size.height / 2);
    final minRadius = this.minRadius ?? 0;
    final maxRadius = this.maxRadius ?? calcMaxRadius(size, center);

    return Path()
      ..addOval(
        Rect.fromCircle(
          center: center,
          radius: lerpDouble(minRadius, maxRadius, fraction)!,
        ),
      );
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => true;

  static double calcMaxRadius(Size size, Offset center) {
    final w = max(center.dx, size.width - center.dx);
    final h = max(center.dy, size.height - center.dy);
    return sqrt(w * w + h * h);
  }
}

class FadeIndexedStack extends StatefulWidget {
  final int index;
  final List<Widget> children;
  final Duration duration;

  const FadeIndexedStack({
    required this.index,
    required this.children,
    this.duration = const Duration(milliseconds: 300),
    super.key,
  });

  @override
  State<FadeIndexedStack> createState() => _FadeIndexedStackState();
}

class _FadeIndexedStackState extends State<FadeIndexedStack> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void didUpdateWidget(FadeIndexedStack oldWidget) {
    if (widget.index != oldWidget.index) {
      _controller.forward(from: 0.0);
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void initState() {
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _controller.forward();
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: IndexedStack(
        index: widget.index,
        children: widget.children,
      ),
    );
  }
}
