import 'package:flutter/foundation.dart' show kIsWeb;

/// Compatibility shim for Flutter SDKs that predate
/// `ImageFilter.isShaderFilterSupported` (added after Flutter 3.24).
///
/// The premium Impeller shader pipeline is unavailable on those SDKs, so glass
/// always renders through the lightweight shader / backdrop-filter path.
const bool isShaderFilterSupported = false;

/// Retained for patches that need to branch on web without importing
/// `foundation` in every file.
const bool compatIsWeb = kIsWeb;
