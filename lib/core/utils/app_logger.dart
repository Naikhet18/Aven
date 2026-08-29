import 'dart:developer' as developer;

/// Thin structured-logging wrapper around `dart:developer`'s `log()`.
///
/// Using `log()` instead of `print`/`debugPrint` means messages carry a
/// `name` (area) and `level`, show up in DevTools with proper severity, and
/// can include the original error/stack trace instead of it being
/// string-interpolated away.
class AppLogger {
  final String area;
  const AppLogger(this.area);

  void debug(String message) => _log(message, level: 500);
  void info(String message) => _log(message, level: 800);

  void warning(String message, [Object? error]) =>
      _log(message, level: 900, error: error);

  void error(String message, [Object? error, StackTrace? stackTrace]) =>
      _log(message, level: 1000, error: error, stackTrace: stackTrace);

  void _log(String message, {required int level, Object? error, StackTrace? stackTrace}) {
    developer.log(
      message,
      name: 'khaopiyo.$area',
      level: level,
      error: error,
      stackTrace: stackTrace,
      time: DateTime.now(),
    );
  }
}
