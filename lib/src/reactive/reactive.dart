import 'package:flutter/foundation.dart';

/// A reactive object similar to Vue's reactive()
class Reactive<T extends Object> extends ChangeNotifier {
  final T _state;
  final Map<String, dynamic> _originalValues = {};
  final Set<String> _changedProperties = {};

  Reactive(this._state) {
    // Store original values for comparison
    if (_state is Map) {
      (_state as Map).forEach((key, value) {
        _originalValues[key.toString()] = value;
      });
    } else {
      // For custom objects, we'll track property changes
      // This is a simplified implementation
    }
  }

  T get state => _state;

  dynamic getProperty(String property) {
    if (_state is Map) {
      return (_state as Map)[property];
    }
    // For custom objects, implement property access
    return null;
  }

  void setProperty(String property, dynamic value) {
    if (_state is Map) {
      final oldValue = (_state as Map)[property];
      if (oldValue != value) {
        (_state as Map)[property] = value;
        _changedProperties.add(property);
        notifyListeners();
      }
    }
    // For custom objects, implement property setting
  }

  bool hasChanged(String property) {
    return _changedProperties.contains(property);
  }
}

/// Create a reactive object
Reactive<T> reactive<T extends Object>(T initialState) {
  return Reactive<T>(initialState);
}