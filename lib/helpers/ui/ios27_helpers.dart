import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart'
    show
        AdaptiveGlass,
        GlassQuality,
        LiquidGlassSettings,
        LiquidOval,
        LiquidRoundedRectangle,
        LiquidRoundedSuperellipse;

/// Motion vocabulary borrowed from LiquidGlass's `GlassMotion`: quick, slightly
/// viscous on the way in and springy on the way out, so glass feels like gel.
class Ios27Motion {
  const Ios27Motion._();

  static const double pressScale = 0.025;
  static const Duration pressIn = Duration(milliseconds: 110);
  static const Duration release = Duration(milliseconds: 360);
  static const Curve pressInCurve = Curves.easeOutCubic;
  static const Curve releaseCurve = Curves.elasticOut;
}


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
    final dark = Ios27.isDark(context);
    final colors = Ios27.glassTint(context);
    final fill = tint ?? colors.first;

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: boxShadow ??
            [
              BoxShadow(
                color: Colors.black.withOpacity(dark ? 0.28 : 0.10),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
      ),
      child: AdaptiveGlass(
        // Very large radii are pills; an oval matches the shader SDF and avoids
        // a radius wider than the widget.
        shape: borderRadius >= 100
            ? const LiquidOval()
            : LiquidRoundedSuperellipse(borderRadius: borderRadius),
        quality: GlassQuality.standard,
        useOwnLayer: true,
        clipBehavior: Clip.antiAlias,
        settings: LiquidGlassSettings(
          blur: blur,
          glassColor: fill.withOpacity(tint != null ? fill.opacity : (dark ? 0.10 : 0.32)),
          thickness: dark ? 14 : 18,
          lightIntensity: dark ? 0.7 : 0.9,
          ambientStrength: dark ? 0.25 : 0.15,
          refractiveIndex: 1.35,
          chromaticAberration: 0.008,
          saturation: 1.25,
        ),
        child: Stack(
          children: [
            if (showBorder)
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: radius,
                      border: Border.all(color: Ios27.glassBorder(context), width: 0.8),
                    ),
                  ),
                ),
              ),
            // Specular highlight along the top edge.
            Positioned(
              top: 0,
              left: 10,
              right: 10,
              child: IgnorePointer(
                child: Container(
                  height: 0.8,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0),
                        Colors.white.withOpacity(dark ? 0.42 : 0.85),
                        Colors.white.withOpacity(0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Rim refraction approximation: a sweep-lit stroke that is
            // bright where the key light hits and dark on the opposite
            // edge, like a polished glass contour.
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _Ios27RimPainter(
                    radius: borderRadius,
                    dark: dark,
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
    );
  }
}

/// Paints the bright/dark sweep around a glass contour to fake the rim
/// refraction of real Liquid Glass without a runtime shader.
class _Ios27RimPainter extends CustomPainter {
  const _Ios27RimPainter({required this.radius, required this.dark});

  final double radius;
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect.deflate(0.8), Radius.circular(radius));
    final shader = SweepGradient(
      startAngle: -2.6,
      endAngle: 3.6,
      colors: [
        Colors.white.withOpacity(dark ? 0.34 : 0.86),
        Colors.white.withOpacity(0.0),
        Colors.black.withOpacity(dark ? 0.30 : 0.10),
        Colors.white.withOpacity(0.0),
        Colors.white.withOpacity(dark ? 0.34 : 0.86),
      ],
      stops: const [0.0, 0.28, 0.55, 0.8, 1.0],
    ).createShader(rect);
    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1
        ..shader = shader,
    );
  }

  @override
  bool shouldRepaint(_Ios27RimPainter oldDelegate) =>
      oldDelegate.radius != radius || oldDelegate.dark != dark;
}

/// A rounded glass card for grouped content, matching the reference library's
/// 24dp `GlassCard`.
class Ios27GlassCard extends StatelessWidget {
  const Ios27GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.margin,
    this.tint,
    this.blur = 22,
    this.borderRadius = Ios27.radius,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final Color? tint;
  final double blur;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Ios27Glass(
      margin: margin,
      padding: padding,
      tint: tint,
      blur: blur,
      borderRadius: borderRadius,
      child: child,
    );
  }
}

/// Edge-to-edge glass used behind app bars and bottom bars. Unlike
/// [Ios27Glass] it is square, so it can sit flush against the screen edges.
class Ios27GlassBar extends StatelessWidget {
  const Ios27GlassBar({
    super.key,
    this.blur = 24,
    this.height,
    this.opacity = 0.72,
    this.showTopHighlight = true,
  });

  final double blur;
  final double? height;
  final double opacity;
  final bool showTopHighlight;

  @override
  Widget build(BuildContext context) {
    final dark = Ios27.isDark(context);
    final base = dark ? const Color(0xFF141518) : Colors.white;

    return SizedBox(
      height: height,
      child: AdaptiveGlass(
        shape: const LiquidRoundedRectangle(borderRadius: 0),
        quality: GlassQuality.standard,
        useOwnLayer: true,
        clipBehavior: Clip.hardEdge,
        settings: LiquidGlassSettings(
          blur: blur,
          glassColor: base.withOpacity((opacity * (dark ? 0.85 : 0.9)).clamp(0.0, 1.0)),
          thickness: 10,
          lightIntensity: dark ? 0.45 : 0.65,
          ambientStrength: dark ? 0.2 : 0.1,
          refractiveIndex: 1.2,
          chromaticAberration: 0.004,
          saturation: 1.15,
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (showTopHighlight)
              Align(
                alignment: Alignment.topCenter,
                child: Container(
                  height: 0.7,
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0),
                        Colors.white.withOpacity(dark ? 0.30 : 0.70),
                        Colors.white.withOpacity(0),
                      ],
                    ),
                  ),
                ),
              ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                height: 0.6,
                color: Ios27.hairline(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Wraps content with the reference library's gel press response: a springy
/// 2.5% scale-up, a short white flash, and a light haptic.
class Ios27Pressable extends StatefulWidget {
  const Ios27Pressable({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.borderRadius,
    this.scale = Ios27Motion.pressScale,
    this.haptic = true,
    this.enabled = true,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final BorderRadius? borderRadius;
  final double scale;
  final bool haptic;
  final bool enabled;

  @override
  State<Ios27Pressable> createState() => _Ios27PressableState();
}

class _Ios27PressableState extends State<Ios27Pressable> {
  bool _pressed = false;

  void _press() {
    if (!widget.enabled || _pressed) return;
    setState(() => _pressed = true);
    if (widget.haptic) HapticFeedback.lightImpact();
  }

  void _release() {
    if (!_pressed) return;
    setState(() => _pressed = false);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: widget.enabled ? (_) => _press() : null,
      onTapUp: widget.enabled ? (_) => _release() : null,
      onTapCancel: widget.enabled ? _release : null,
      onTap: widget.enabled ? widget.onTap : null,
      onLongPress: widget.enabled ? widget.onLongPress : null,
      child: AnimatedScale(
        scale: _pressed ? 1 + widget.scale : 1,
        duration: _pressed ? Ios27Motion.pressIn : Ios27Motion.release,
        curve: _pressed ? Ios27Motion.pressInCurve : Ios27Motion.releaseCurve,
        child: Stack(
          children: [
            widget.child,
            if (_pressed)
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(Ios27.isDark(context) ? 0.10 : 0.18),
                      borderRadius: widget.borderRadius,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// A button that lives inside an [Ios27GlassCluster]. It deliberately has no
/// glass of its own so the cluster's single surface can merge the controls.
class Ios27ClusterButton extends StatelessWidget {
  const Ios27ClusterButton({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.size = 48,
    this.tooltip,
    this.color,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double size;
  final String? tooltip;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    Widget button = Ios27Pressable(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(size / 2),
      child: SizedBox(
        width: size,
        height: size,
        child: Center(
          child: IconTheme(
            data: IconThemeData(color: color ?? Ios27.primaryText(context), size: 22),
            child: child,
          ),
        ),
      ),
    );
    if (tooltip != null) button = Tooltip(message: tooltip!, child: button);
    return button;
  }
}

/// One shared liquid surface for a cluster of controls (the reference
/// library's `GlassEffectContainer`): adjacent buttons melt into one pill
/// instead of showing separate overlapping glass pieces.
class Ios27GlassCluster extends StatelessWidget {
  const Ios27GlassCluster({
    super.key,
    required this.children,
    this.axis = Axis.vertical,
    this.spacing = 4,
    this.padding = const EdgeInsets.all(6),
    this.borderRadius = 32,
    this.tint,
    this.blur = 22,
  });

  final List<Widget> children;
  final Axis axis;
  final double spacing;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final Color? tint;
  final double blur;

  @override
  Widget build(BuildContext context) {
    final separated = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) {
        separated.add(SizedBox(
          width: axis == Axis.horizontal ? spacing : 0,
          height: axis == Axis.vertical ? spacing : 0,
        ));
      }
      separated.add(children[i]);
    }
    return Ios27Glass(
      borderRadius: borderRadius,
      tint: tint,
      blur: blur,
      padding: padding,
      child: Flex(
        direction: axis,
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: separated,
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
    Widget button = FocusableActionDetector(
      focusNode: focusNode,
      enabled: onTap != null || onLongPress != null,
      mouseCursor: onTap != null ? SystemMouseCursors.click : MouseCursor.defer,
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
      },
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            onTap?.call();
            return null;
          },
        ),
      },
      child: Ios27Pressable(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(size / 2),
        child: SizedBox(
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
    final pill = Ios27Glass(
      borderRadius: Ios27.pillRadius,
      blur: 20,
      tint: tint,
      child: content,
    );
    if (onTap == null) return pill;
    return Ios27Pressable(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Ios27.pillRadius),
      child: pill,
    );
  }
}
