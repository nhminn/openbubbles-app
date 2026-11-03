import 'dart:async';
import 'dart:typed_data';

import 'package:bluebubbles/src/rust/api/api.dart' as api;
import 'package:bluebubbles/utils/logger/logger.dart';
import 'package:flutter/services.dart';

/// Mints Apple's 517-byte validation-data stamp for the current Mac hardware
/// config and installs it into the Rust sign-in path.
///
/// The two HTTP calls stay in Rust (BoringSSL/rustls, which Apple accepts).
/// The byte-exact NAC mint is a vendored Kotlin implementation because the
/// public OpenAbsinthe crate is only a stub.
class ValidationDataService {
  static const MethodChannel _channel = MethodChannel('com.bluebubbles.messaging/validation');
  static const Duration _maxAge = Duration(minutes: 10);

  static Uint8List? _cachedSession;
  static Uint8List? _cachedStamp;
  static DateTime? _cachedAt;

  /// The reason the most recent [ensure] call could not prepare a stamp.
  /// Sign-in errors include this so a rejected delegate login explains itself.
  static String? lastError;

  /// Serializes mints. The Kotlin bridge keeps the establish seed between
  /// `createRequest` and `finish`, so two concurrent mints would overwrite each
  /// other's seed and both stamps would be rejected.
  static Future<void> _queue = Future<void>.value();

  /// Returns true when a stamp is installed for [config]. Relay configs return
  /// false (their validation data comes from the relay), and any mint failure
  /// is non-fatal so sign-in can still be attempted.
  ///
  /// Pass [forceRefresh] to ignore a cached stamp, for example after Apple
  /// rejected a delegate login.
  static Future<bool> ensure(api.JoinedOsConfig config, {bool forceRefresh = false}) {
    final completer = Completer<bool>();
    _queue = _queue.then((_) async {
      try {
        completer.complete(await _ensure(config, forceRefresh: forceRefresh));
      } catch (e, s) {
        lastError = e.toString();
        Logger.error('Failed to generate validation data', error: e, trace: s);
        completer.complete(false);
      }
    });
    return completer.future;
  }

  static Future<bool> _ensure(api.JoinedOsConfig config, {required bool forceRefresh}) async {
    lastError = null;

    final session = await api.getValidationSessionData(config: config);
    if (session == null) {
      // Relay/hosted configs mint their stamp server-side.
      lastError = 'this account is hosted; validation is prepared by the server';
      return false;
    }

    if (!forceRefresh &&
        _cachedSession != null &&
        _sameBytes(_cachedSession!, session) &&
        _cachedStamp != null &&
        _cachedAt != null &&
        DateTime.now().difference(_cachedAt!) < _maxAge) {
      await api.setValidationData(config: config, data: _cachedStamp!);
      return true;
    }

    final cert = await api.fetchValidationCert();
    final request = await _channel.invokeMethod<Uint8List>('createRequest', {'cert': cert});
    if (request == null) {
      lastError = 'the device stamp request could not be created';
      return false;
    }

    final sessionInfo = await api.initializeValidation(request: request);
    final stamp = await _channel.invokeMethod<Uint8List>('finish', {
      'sessionInfo': sessionInfo,
      'session250': session,
    });
    if (stamp == null) {
      lastError = 'the device stamp could not be finalized';
      return false;
    }

    await api.setValidationData(config: config, data: stamp);
    _cachedSession = session;
    _cachedStamp = stamp;
    _cachedAt = DateTime.now();
    Logger.info('Generated validation data (${stamp.length} bytes)');
    return true;
  }

  static bool _sameBytes(Uint8List a, Uint8List b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
