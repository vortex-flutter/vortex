import 'package:flutter/foundation.dart';

/// A computed value similar to Vue's computed()
class Computed<T> extends ChangeNotifier {
  final T Function() _compute;
  late T _value;
  final List<Listenable> _dependencies = [];

  Computed(this._compute) {
    _value = _compute();
  }

  void addDependency(Listenable dependency) {
    _dependencies.add(dependency);
    dependency.addListener(_recompute);
  }

  void _recompute() {
    final newValue = _compute();
    if (_value != newValue) {
      _value = newValue;
      notifyListeners();
    }
  }

  T get value {
    return _value;
  }

  @override
  void dispose() {
    for (final dep in _dependencies) {
      dep.removeListener(_recompute);
    }
    super.dispose();
  }
}

/// Create a computed value
Computed<T> computed<T>(T Function() compute, {List<Listenable>? dependencies}) {
  final computedValue = Computed<T>(compute);
  if (dependencies != null) {
    for (final dep in dependencies) {
      computedValue.addDependency(dep);
    }
  }
  return computedValue;
}