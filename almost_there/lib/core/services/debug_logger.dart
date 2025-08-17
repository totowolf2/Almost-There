/// Simple debug logger for development
class DebugLogger {
  static const bool _isDebugMode = true; // Could be tied to build config
  
  /// Log debug message
  static void debug(String message) {
    if (_isDebugMode) {
      // In production, this would use a proper logging framework
      // ignore: avoid_print
      print(message);
    }
  }
  
  /// Log warning message
  static void warning(String message) {
    if (_isDebugMode) {
      // ignore: avoid_print
      print('⚠️ $message');
    }
  }
  
  /// Log error message
  static void error(String message) {
    if (_isDebugMode) {
      // ignore: avoid_print
      print('❌ $message');
    }
  }
  
  /// Log info message
  static void info(String message) {
    if (_isDebugMode) {
      // ignore: avoid_print
      print('ℹ️ $message');
    }
  }
}