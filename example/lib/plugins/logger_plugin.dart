import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:vortex/vortex.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum LogLevel { debug, info, warning, error }

@VortexPlugin('logger')
class LoggerPlugin extends Plugin {
  final Map<String, dynamic> _helpers = {};
  final List<String> _logHistory = [];
  final int _maxHistorySize = 100;
  LogLevel _minLogLevel = LogLevel.debug;
  bool _isPersistent = false;
  static const String _storageKey = 'vortex_logs';

  @override
  String get name => 'logger';

  LoggerPlugin()
    : super(
        enforce: 'pre',
        parallel: true,
        dependsOn: const [],
        setup: (app) async {
          return {};
        },
      );

  @override
  Future<void> initialize() async {
    _helpers['info'] = info;
    _helpers['warning'] = warning;
    _helpers['error'] = error;
    _helpers['debug'] = debug;
    _helpers['getHistory'] = getHistory;
    _helpers['clearHistory'] = clearHistory;
    _helpers['setLogLevel'] = setLogLevel;
    _helpers['getLogLevel'] = getLogLevel;
    _helpers['setPersistence'] = setPersistence;
    _helpers['filterLogs'] = filterLogs;
    _helpers['exportLogs'] = exportLogs;

    if (_isPersistent) {
      await _loadPersistedLogs();
    }
  }

  @override
  Future<void> onAppStart(BuildContext context) async {
    info('Application started');
  }

  @override
  Future<void> onAppClose() async {
    info('Application closed');
    if (_isPersistent) {
      await _persistLogs();
    }
  }

  @override
  dynamic getHelper(String name) {
    return _helpers[name];
  }

  @override
  bool hasHelper(String name) {
    return _helpers.containsKey(name);
  }

  @override
  Map<String, dynamic> get helpers => Map.from(_helpers);

  // Enhanced logging methods
  void info(String message) {
    if (_minLogLevel.index <= LogLevel.info.index) {
      _addToHistory('INFO: $message');
      Log.i(message);
    }
  }

  void warning(String message) {
    if (_minLogLevel.index <= LogLevel.warning.index) {
      _addToHistory('WARNING: $message');
      Log.w(message);
    }
  }

  void error(String message, [dynamic error, StackTrace? stackTrace]) {
    if (_minLogLevel.index <= LogLevel.error.index) {
      _addToHistory('ERROR: $message${error != null ? ' - $error' : ''}');
      if (stackTrace != null) {
        _addToHistory('STACK TRACE: $stackTrace');
      }
      Log.e(message, error);
    }
  }

  void debug(String message) {
    if (_minLogLevel.index <= LogLevel.debug.index) {
      _addToHistory('DEBUG: $message');
      Log.d(message);
    }
  }

  // Log management methods
  List<String> getHistory() {
    return List.from(_logHistory);
  }

  void clearHistory() {
    _logHistory.clear();
    if (_isPersistent) {
      _persistLogs();
    }
  }

  void setLogLevel(LogLevel level) {
    _minLogLevel = level;
    info('Log level set to: $level');
  }

  LogLevel getLogLevel() {
    return _minLogLevel;
  }

  void setPersistence(bool enabled) {
    _isPersistent = enabled;
    if (enabled) {
      _persistLogs();
    }
  }

  List<String> filterLogs(String query, {LogLevel? level}) {
    return _logHistory.where((log) {
      final matchesQuery = log.toLowerCase().contains(query.toLowerCase());
      if (level != null) {
        final matchesLevel = log.contains(level.toString().toUpperCase());
        return matchesQuery && matchesLevel;
      }
      return matchesQuery;
    }).toList();
  }

  String exportLogs() {
    return jsonEncode(_logHistory);
  }

  // Private helper methods
  void _addToHistory(String logEntry) {
    final timestamp = DateTime.now().toIso8601String();
    _logHistory.add('$timestamp: $logEntry');
    if (_logHistory.length > _maxHistorySize) {
      _logHistory.removeAt(0);
    }
    if (_isPersistent) {
      _persistLogs();
    }
  }

  Future<void> _persistLogs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, jsonEncode(_logHistory));
    } catch (e) {
      Log.e('Failed to persist logs', e);
    }
  }

  Future<void> _loadPersistedLogs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final logs = prefs.getString(_storageKey);
      if (logs != null) {
        _logHistory.clear();
        _logHistory.addAll(List<String>.from(jsonDecode(logs)));
      }
    } catch (e) {
      Log.e('Failed to load persisted logs', e);
    }
  }
}

// Register the plugin
void registerLoggerPlugin() {
  Vortex.registerPlugin(LoggerPlugin());
}
