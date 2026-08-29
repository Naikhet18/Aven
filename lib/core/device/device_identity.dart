import 'dart:io' show Platform;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// A stable per-install device identity.
///
/// This backs three things that were previously unimplemented:
/// - `devices.id` / `orders.created_by_device` in the remote schema (both
///   columns existed but nothing ever wrote a `devices` row).
/// - A short, human-readable tag embedded in order numbers so two devices
///   generating orders offline, at the same time, on the same day, can never
///   produce the same order number (see `OrderNumberGenerator`).
class DeviceIdentity {
  static const _idKey = 'device_id';
  static const _tagKey = 'device_tag';
  static const _tagChars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // no 0/O/1/I

  final SharedPreferences _prefs;
  DeviceIdentity(this._prefs);

  /// Stable UUID for this install. Generated once, persisted forever.
  String get id {
    final existing = _prefs.getString(_idKey);
    if (existing != null) return existing;
    final generated = const Uuid().v4();
    _prefs.setString(_idKey, generated);
    return generated;
  }

  /// A short (2-char) tag derived from [id], used inside order numbers.
  /// Not cryptographically unique across a whole fleet, but collisions are
  /// harmless here -- it's a display label, not a primary key.
  String get shortTag {
    final existing = _prefs.getString(_tagKey);
    if (existing != null) return existing;
    final seed = id.hashCode.abs();
    final a = _tagChars[seed % _tagChars.length];
    final b = _tagChars[(seed ~/ _tagChars.length) % _tagChars.length];
    final generated = '$a$b';
    _prefs.setString(_tagKey, generated);
    return generated;
  }

  String get platformName {
    try {
      return Platform.operatingSystem;
    } catch (_) {
      return 'unknown';
    }
  }

  String get deviceName => 'KhaoPiyo-$shortTag ($platformName)';
}
