import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Compatibility shims for Flutter APIs added after 3.24:
/// `BackdropGroup`, `BackdropKey`, `BackdropFilterLayer.backdropKey`, and
/// `ImageFilter.shader`.
///
/// The premium Impeller pipeline that uses these is disabled at runtime on
/// Flutter 3.24 (`isShaderFilterSupported == false`), so the shims only need
/// to keep the code compiling and be inert if ever reached.
class BackdropKey {
  const BackdropKey();
}

/// Inert replacement for Flutter's `BackdropGroup`.
class BackdropGroup extends StatelessWidget {
  const BackdropGroup({super.key, required this.child});

  final Widget child;

  static BackdropGroup? of(BuildContext context) => null;

  BackdropKey? get backdropKey => null;

  @override
  Widget build(BuildContext context) => child;
}

/// No-op blur-sharing key setter on [BackdropFilterLayer].
extension CompatBackdropFilterLayer on BackdropFilterLayer {
  // ignore: avoid_setters_without_getters
  set backdropKey(BackdropKey? value) {}
}

/// Inert replacement for `ImageFilter.shader(FragmentShader)`.
ui.ImageFilter compatShaderFilter(ui.FragmentShader shader) =>
    ui.ImageFilter.blur(sigmaX: 0.01, sigmaY: 0.01);
