import 'package:flutter/foundation.dart';

/// A reactive reference similar to Vue's ref()
class Ref<T> extends ChangeNotifier {
  T _value;

  Ref(this._value);

  T get value => _value;

  set value(T newValue) {
    if (_value != newValue) {
      _value = newValue;
      notifyListeners();
    }
  }

  void update(T Function(T currentValue) updater) {
    final newValue = updater(_value);
    if (_value != newValue) {
      _value = newValue;
      notifyListeners();
    }
  }
}

/// Create a reactive reference
Ref<T> ref<T>(T initialValue) {
  return Ref<T>(initialValue);
}