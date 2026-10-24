import 'dart:ui';

import 'package:flutter/material.dart';

/// Design tokens and surfaces for the iOS 27 "Liquid Glass 2.0" look.
///
/// iOS 27 keeps the glass material but diffuses the background, adds a darker
/// hairline around translucent controls, and varies opacity by function: chrome
/// stays glassy while content-bearing surfaces are more tinted for contrast.
class Ios27 {
  const Ios27._();

  static const double radius = 24;
  static const double smallRadius = 16;
  static const double pillRadius = 999;

  static const Color blue = Color(0xFF0A84FF);
  static const Color green = Color(0xFF30D158);
  static const Color purple = Color(0xFFBF5AF2);

  static bool isDark(BuildContext context) => Theme.of(context).brightness == Brightness.dark;

  static Color primaryText(BuildContext context) =>
      isDark(context) ? Colors.white.withOpacity(0.96) : const Color(0xFF0B0B0F);

  static Color secondaryText(BuildContext context) =>
      isDark(context) ? Colors.white.withOpacity(0.58) : const Color(0xFF6C6C70);

  static Color hairline(BuildContext context) =>
      isDark(context) ? Colors.white.withOpacity(0.10) : Colors.black.withOpacity(0.08);

  static Color glassBorder(BuildContext context) =>
      isDark(context) ? Colors.white.withOpacity(0.18) : Colors.white.withOpacity(0.72);

  static List<Color> glassTint(BuildContext context) => isDark(context)
      ? [Colors.white.withOpacity(0.10), Colors.white.withOpacity(0.045)]
      : [Colors.white.withOpacity(0.62), Colors.white.withOpacity(0.38)];

  static Color chromeTint(BuildContext context) =>
      isDark(context) ? const Color(0xFF1C1C1E).withOpacity(0.72) : Colors.white.withOpacity(0.72);
}

/// A soft, diffused wallpaper used behind the glass chrome. The gradients are
/// deliberately low-contrast so text and bubbles keep priority.
class Ios27Background extends StatelessWidget {
  const Ios27Background({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final dark = Ios27.isDark(context);
    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: dark ? const Color(0xFF08090C) : const Color(0xFFF6F7FB)),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(-0.85, -0.9),
              radius: 1.15,
              colors: [
                (dark ? Ios27.blue : const Color(0xFF7FB8FF)).withOpacity(dark ? 0.20 : 0.30),
                Colors.transparent,
              ],
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(1.0, 0.15),
              radius: 0.95,
              colors: [
                (dark ? Ios27.purple : const Color(0xFFD9C7FF)).withOpacity(dark ? 0.16 : 0.26),
                Colors.transparent,
              ],
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(-0.2, 1.1),
              radius: 1.0,
              colors: [
                (dark ? const Color(0xFF0A6C74) : const Color(0xFFBDEBE8)).withOpacity(dark ? 0.14 : 0.30),
                Colors.transparent,
              ],
            ),
          ),
        ),
        child,
      ],
    );
  }
}

/// Translucent, blurred surface with a bright top-left reflection and a
/// hairline edge, mirroring the iOS 27 glass treatment.
class Ios27Glass extends StatelessWidget {
  const Ios27Glass({
    super.key,
    required this.child,
    this.borderRadius = Ios27.radius,
    this.padding,
    this.blur = 24,
    this.tint,
    this.showBorder = true,
    this.boxShadow,
    this.margin,
  });

  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final double blur;
  final Color? tint;
  final bool showBorder;
  final List<BoxShadow>? boxShadow;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);
    final colors = Ios27.glassTint(context);
    final fill = tint ?? colors.first;
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: boxShadow ??
            [
              BoxShadow(
                color: Colors.black.withOpacity(Ios27.isDark(context) ? 0.28 : 0.10),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: radius,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  fill.withOpacity((fill.opacity * 1.12).clamp(0.0, 1.0).toDouble()),
                  (tint ?? colors.last).withOpacity(((tint ?? colors.last).opacity * 0.94).clamp(0.0, 1.0).toDouble()),
                ],
              ),
              border: showBorder ? Border.all(color: Ios27.glassBorder(context), width: 0.8) : null,
            ),
            child: Stack(
              children: [
                // Specular highlight along the top edge.
                Positioned(
                  top: 0,
                  left: 10,
                  right: 10,
                  child: Container(
                    height: 0.8,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withOpacity(0),
                          Colors.white.withOpacity(Ios27.isDark(context) ? 0.42 : 0.85),
                          Colors.white.withOpacity(0),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: padding ?? EdgeInsets.zero,
                  child: child,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Circular glass control used for header and toolbar actions.
class Ios27GlassButton extends StatelessWidget {
  const Ios27GlassButton({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.size = 38,
    this.padding = EdgeInsets.zero,
    this.tint,
    this.tooltip,
    this.focusNode,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double size;
  final EdgeInsetsGeometry padding;
  final Color? tint;
  final String? tooltip;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    Widget button = SizedBox(
      width: size,
      height: size,
      child: Ios27Glass(
        borderRadius: size / 2,
        blur: 18,
        tint: tint,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(Ios27.isDark(context) ? 0.22 : 0.08),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            focusNode: focusNode,
            customBorder: const CircleBorder(),
            onTap: onTap,
            onLongPress: onLongPress,
            child: Padding(
              padding: padding,
              child: Center(child: child),
            ),
          ),
        ),
      ),
    );
    if (tooltip != null) {
      button = Tooltip(message: tooltip!, child: button);
    }
    return button;
  }
}

/// A compact glass pill, useful for titles and status chips.
class Ios27GlassPill extends StatelessWidget {
  const Ios27GlassPill({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    this.onTap,
    this.tint,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final content = Padding(padding: padding, child: child);
    return Ios27Glass(
      borderRadius: Ios27.pillRadius,
      blur: 20,
      tint: tint,
      child: onTap == null
          ? content
          : Material(
              color: Colors.transparent,
              child: InkWell(
                customBorder: const StadiumBorder(),
                onTap: onTap,
                child: content,
              ),
            ),
    );
  }
}
