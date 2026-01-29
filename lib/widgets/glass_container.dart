import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../core/ui/biz_theme.dart';

class GlassContainer extends StatefulWidget {
  final Widget child;
  final double blurAmount;
  final double opacity;
  final Gradient? gradient;
  final double parallaxIntensity;
  final EdgeInsets padding;
  final VoidCallback? onTap;

  const GlassContainer({
    super.key,
    required this.child,
    this.blurAmount = 10.0,
    this.opacity = 0.1,
    this.gradient,
    this.parallaxIntensity = 50,
    this.padding = const EdgeInsets.all(24.0),
    this.onTap,
  });

  @override
  State<GlassContainer> createState() => _GlassContainerState();
}

class _GlassContainerState extends State<GlassContainer> {
  double _tiltX = 0;
  double _tiltY = 0;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      accelerometerEventStream().listen((event) {
        if (mounted) {
          setState(() {
            _tiltX = event.y * (widget.parallaxIntensity / 1000);
            _tiltY = -event.x * (widget.parallaxIntensity / 1000);
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final defaultGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Colors.white.withValues(alpha: widget.opacity),
        BizTheme.slovakBlue.withValues(alpha: widget.opacity * 0.5),
      ],
    );

    return GestureDetector(
      onTap: widget.onTap,
      child: Transform(
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.001)
          ..rotateX(_tiltX * 0.01)
          ..rotateY(_tiltY * 0.01),
        alignment: Alignment.center,
        child: Container(
          decoration: BoxDecoration(
            gradient: widget.gradient ?? defaultGradient,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: BizTheme.slovakBlue.withValues(alpha: 0.15),
                blurRadius: 24,
                offset: const Offset(0, 8),
                spreadRadius: 2,
              ),
            ],
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: widget.blurAmount,
              sigmaY: widget.blurAmount,
            ),
            child: Padding(
              padding: widget.padding,
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}
