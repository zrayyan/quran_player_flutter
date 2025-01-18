import 'package:intl/intl.dart';

class Logger {
  final DateFormat _dateFormatter = DateFormat('yyyy-MM-dd HH:mm:ss');

  void info(String message) {
    _log('INFO', message);
  }

  void error(String message) {
    _log('ERROR', message);
  }

  void warning(String message) {
    _log('WARN', message);
  }

  void debug(String message) {
    _log('DEBUG', message);
  }

  void _log(String level, String message) {
    final timestamp = _dateFormatter.format(DateTime.now().toUtc());
    print('[$timestamp] $level: $message');
  }
}
