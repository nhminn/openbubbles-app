# Vendored `liquid_glass_widgets`

This directory contains a **vendored, locally patched** copy of
[`liquid_glass_widgets`](https://github.com/sdegenaar/liquid_glass_widgets)
version **0.18.4** (published on pub.dev, MIT licensed, © 2024 Sebastian
Degenaar — see `LICENSE`).

It is vendored because the app is pinned to Flutter **3.24**, while the package
(despite declaring Flutter >= 3.24) uses several APIs added in later Flutter
releases.

## Local changes

All local edits are marked with `[LOCAL PATCH]` where practical.

- Replaced `Color.withValues(alpha:)` with `Color.withOpacity(...)`.
- Replaced `Color` `.a/.r/.g/.b` getters with `.opacity/.red/.green/.blue`.
- Replaced `Color.from(...)` constants with equivalent 8-bit `Color(0x...)`
  values.
- Added `lib/src/compat/shader_support.dart`: `ImageFilter.isShaderFilterSupported`
  does not exist on 3.24, and the premium Impeller pipeline is unavailable
  there. It is pinned to `false`, so glass always uses the lightweight
  shader / backdrop-filter renderer.
- Added `lib/src/compat/backdrop_support.dart`: inert `BackdropGroup` /
  `BackdropKey` / `BackdropFilterLayer.backdropKey` / `ImageFilter.shader`
  shims for the unreachable premium render path.
- Removed `FragmentShader.setImageSampler(filterQuality:)` arguments.
- Replaced `RoundedSuperellipseBorder` with `RoundedRectangleBorder` for the
  equivalent border paths (the glass geometry shader still renders the
  superellipse silhouette).
- Replaced `Matrix4.translateByDouble/scaleByDouble` with
  `translate/scale`.
- Inlined Flutter's newer `SpringDescription.withDurationAndBounce` factory in
  `lib/utils/glass_spring.dart`.
- Replaced `Row`/`Column` `spacing:` with explicit separators.
- Replaced `CupertinoButton(minimumSize:)` with `minSize:`.
- Removed the upstream `example/`, dev dependencies, and repository-only
  metadata so the package resolves on Flutter 3.24 / Dart 3.5.

## Updating

Re-vendor from the newest upstream release that is known to work with Flutter
3.24, then re-apply the patches above and run:

```sh
flutter analyze packages/liquid_glass_widgets/lib
```
