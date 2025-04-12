import 'package:flutter/foundation.dart';

/// A watcher similar to Vue's watch()
class Watcher<T> {
  final Listenable _source;
  final void Function(T newValue, T? oldValue) _callback;
  T? _oldValue;
  bool _immediate;
  bool _isActive = true;

  Watcher(this._source, T Function() getter, this._callback, {bool immediate = false})
      : _immediate = immediate {
    _oldValue = getter();
    
    if (_immediate) {
      _callback(_oldValue as T, null);
    }
    
    _source.addListener(() {
      if (_isActive) {
        final newValue = getter();
        if (newValue != _oldValue) {
          _callback(newValue, _oldValue);
          _oldValue = newValue;
        }
      }
    });
  }

  void stop() {
    _isActive = false;
  }
}

/// Watch a reactive source
Watcher<T> watch<T>(
  Listenable source,
  T Function() getter,
  void Function(T newValue, T? oldValue) callback, {
  bool immediate = false,
}) {
  return Watcher<T>(source, getter, callback, immediate: immediate);
}