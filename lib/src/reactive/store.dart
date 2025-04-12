import 'package:flutter/foundation.dart';
import 'package:vortex/src/reactive/ref.dart';
import 'package:vortex/src/reactive/reactive.dart';
import 'package:vortex/src/reactive/computed.dart';
import 'package:vortex/src/reactive/watch.dart';

/// A global store for reactive variables
class ReactiveStore {
  static final ReactiveStore _instance = ReactiveStore._internal();
  factory ReactiveStore() => _instance;
  ReactiveStore._internal();

  final Map<String, dynamic> _store = {};

  /// Get or create a reactive reference
  Ref<T> getRef<T>(String key, T initialValue) {
    if (!_store.containsKey(key)) {
      _store[key] = Ref<T>(initialValue);
    }
    return _store[key] as Ref<T>;
  }

  /// Get or create a reactive object
  Reactive<T> getReactive<T extends Object>(String key, T initialState) {
    if (!_store.containsKey(key)) {
      _store[key] = Reactive<T>(initialState);
    }
    return _store[key] as Reactive<T>;
  }

  /// Get or create a computed value
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

  /// Get or create a watcher
  Watcher<T> getWatcher<T>(String key) {
    return _store[key] as Watcher<T>;
  }

  /// Set a watcher
  void setWatcher<T>(String key, Watcher<T> watcher) {
    _store[key] = watcher;
  }

  /// Check if a key exists in the store
  bool hasKey(String key) {
    return _store.containsKey(key);
  }

  /// Remove a key from the store
  void removeKey(String key) {
    _store.remove(key);
  }
}