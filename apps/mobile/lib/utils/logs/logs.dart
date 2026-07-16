import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// A wrapper class for [Logger] to log messages.
class Logs {
  /// The logger instance.
  static final Logger _logger = Logger(
    printer: PrettyPrinter(),
    level: kDebugMode ? Level.debug : Level.nothing,
  );

  /// Logs a message at level [Level.debug].
  static void d(Object message) {
    _logger.d(message);
  }

  /// Logs a message at level [Level.error].
  static void e(Object message) {
    _logger.e(message);
  }

  /// Logs a message at level [Level.info].
  static void i(Object message) {
    _logger.i(message);
  }

  /// Logs a message at level [Level.warning].
  static void w(Object message) {
    _logger.w(message);
  }
}
