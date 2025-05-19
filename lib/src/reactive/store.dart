import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vortex/vortex.dart';

class ReactiveStore {
  static final ReactiveStore _instance = ReactiveStore._internal();
  static SharedPreferences? _prefs;
  static bool _isInitialized = false;
  static bool _isPersistentEnabled = false;

  factory ReactiveStore() {
    if (!_isInitialized) {
      throw StateError(
        'ReactiveStore must be initialized before use. Call ReactiveStore.initialize() first.',
      );
    }
    return _instance;
  }

  final Map<String, dynamic> _store = {};
  final Map<String, bool> _persistent = {};

  ReactiveStore._internal();

  static Future<void> initialize({
    bool persistentEnabled = false,
    bool logEnabled = false,
  }) async {
    if (_isInitialized) {
      Log.i('Store already initialized, skipping...');
      return;
    }

    _isPersistentEnabled = persistentEnabled;
    if (!persistentEnabled) {
      Log.i('Persistent storage disabled, skipping initialization');
      _isInitialized = true;
      return;
    }

    try {
      Log.i('Initializing SharedPreferences...');
      _prefs = await SharedPreferences.getInstance();
      Log.i('SharedPreferences initialized successfully');
      _isInitialized = true;
      Log.i('Store initialization completed');
    } catch (e) {
      Log.e('Error initializing persistent storage: $e');
      _prefs = null;
      rethrow;
    }
  }

  Future<void> _loadPersistentState() async {
    if (_prefs == null) {
      Log.w(
        'SharedPreferences not initialized, skipping persistent state load',
      );
      return;
    }

    Log.i('Loading persistent state...');
    for (final key in _prefs!.getKeys()) {
      try {
        final rawValue = _prefs!.get(key);
        Log.i('Loading key: $key, raw value: $rawValue');
        dynamic value = rawValue;

        if (value is String) {
          try {
            value = json.decode(value);
            Log.i('Decoded JSON for key $key: $value');
          } catch (_) {
            Log.i('Using raw string value for key $key: $value');
          }
        }

        _store[key] = value;
        _persistent[key] = true;
        Log.i('Successfully loaded persistent key: $key');
      } catch (e) {
        Log.e('Error loading key $key: $e');
      }
    }
    Log.i('Persistent state loading completed');
  }

  T? getState<T>(String key, {bool persistent = false}) {
    Log.i('Getting state for key: $key, type: $T, persistent: $persistent');
    Log.i('Persistent storage enabled: $_isPersistentEnabled');
    Log.i('SharedPreferences: $_prefs');
    Log.i('Persistent state: $_persistent');

    if (persistent && _prefs != null && _prefs!.containsKey(key)) {
      try {
        final dynamic raw = _prefs!.get(key);
        Log.i('Raw value from persistent storage: $raw (${raw.runtimeType})');

        if (T == bool) {
          if (raw is bool) {
            Log.i('Returning boolean value: $raw');
            return raw as T;
          }
          if (raw is String) {
            final boolValue = raw.toLowerCase() == 'true';
            Log.i('Converting string to boolean: $raw -> $boolValue');
            return boolValue as T;
          }
          if (raw is int) {
            final boolValue = raw != 0;
            Log.i('Converting int to boolean: $raw -> $boolValue');
            return boolValue as T;
          }
          Log.w('Could not convert value to boolean: $raw');
          return null;
        } else if (T == int) {
          if (raw is int) return raw as T;
          if (raw is String) return int.tryParse(raw) as T;
        } else if (T == double) {
          if (raw is double) return raw as T;
          if (raw is String) return double.tryParse(raw) as T;
        } else if (T == String) {
          if (raw is String) return raw as T;
          return raw.toString() as T;
        } else if (T == List<String>) {
          if (raw is List<String>) return raw as T;
          if (raw is String) {
            try {
              final decoded = json.decode(raw) as List;
              if (decoded.every((item) => item is String)) {
                return decoded as T;
              }
            } catch (_) {}
          }
        } else if (raw is String) {
          try {
            final decoded = json.decode(raw);
            if (decoded is T) return decoded;
          } catch (_) {}
        }
      } catch (e) {
        Log.e('Error getting persistent state for key $key: $e');
      }
    }

    final val = _store[key];
    Log.i('Falling back to in-memory store value: $val (${val?.runtimeType})');
    if (val is T) return val;
    return null;
  }

  Future<void> setState(
    String key,
    dynamic value, {
    bool persistent = false,
  }) async {
    Log.i(
      'Setting state for key: $key, value: $value (${value.runtimeType}), persistent: $persistent',
    );
    _store[key] = value;

    if (persistent || _isPersistentEnabled) {
      Log.i('Saving to persistent storage: $key = $value');
      _persistent[key] = true;
      try {
        await _savePersistentState(key, value);
        // Verify the save
        if (_prefs != null) {
          final savedValue = _prefs!.get(key);
          Log.i(
            'Verified saved value for $key: $savedValue (${savedValue.runtimeType})',
          );
        }
      } catch (e) {
        Log.e('Error saving persistent state for key $key: $e');
        rethrow;
      }
    } else {
      _persistent[key] = false;
      Log.i('Skipping persistent storage for key: $key');
    }
  }

  Future<void> _savePersistentState(String key, dynamic value) async {
    if (_prefs == null) {
      Log.w('SharedPreferences not initialized, skipping save for key: $key');
      return;
    }

    try {
      Log.i(
        'Saving persistent state for key: $key, value: $value (${value.runtimeType})',
      );
      if (value is bool) {
        await _prefs!.setBool(key, value);
        Log.i('Saved boolean value: $value');
      } else if (value is int) {
        await _prefs!.setInt(key, value);
        Log.i('Saved integer value: $value');
      } else if (value is double) {
        await _prefs!.setDouble(key, value);
        Log.i('Saved double value: $value');
      } else if (value is String) {
        await _prefs!.setString(key, value);
        Log.i('Saved string value: $value');
      } else if (value is List<String>) {
        await _prefs!.setStringList(key, value);
        Log.i('Saved string list: $value');
      } else {
        final jsonValue = json.encode(value);
        await _prefs!.setString(key, jsonValue);
        Log.i('Saved JSON value: $jsonValue');
      }
      Log.i('Successfully saved persistent state for key: $key');
    } catch (e) {
      Log.e('Error saving key $key: $e');
      rethrow;
    }
  }

  Ref<T> getRef<T>(String key, T initialValue) {
    if (!_store.containsKey(key)) {
      _store[key] = Ref<T>(initialValue);
    }
    return _store[key] as Ref<T>;
  }

  Reactive<T> getReactive<T extends Object>(String key, T initialState) {
    if (!_store.containsKey(key)) {
      _store[key] = Reactive<T>(initialState);
    }
    return _store[key] as Reactive<T>;
  }

  Computed<T> getComputed<T>(
    String key,
    T Function() compute, {
    List<Listenable>? dependencies,
  }) {
    if (!_store.containsKey(key)) {
      final computed = Computed<T>(compute);
      if (dependencies != null) {
        for (final dep in dependencies) {
          computed.addDependency(dep);
        }
      }
      _store[key] = computed;
    }
    return _store[key] as Computed<T>;
  }

  Watcher<T> getWatcher<T>(String key) {
    return _store[key] as Watcher<T>;
  }

  void setWatcher<T>(String key, Watcher<T> watcher) {
    _store[key] = watcher;
  }

  bool hasKey(String key) => _store.containsKey(key);

  Future<void> removeKey(String key) async {
    _store.remove(key);
    _persistent.remove(key);
    if (_prefs != null) {
      await _prefs!.remove(key);
    }
  }
}
