import 'package:flutter/widgets.dart';
import 'package:vortex/src/reactive/ref.dart';
import 'package:vortex/src/reactive/reactive.dart';
import 'package:vortex/src/reactive/computed.dart';
import 'package:vortex/src/reactive/watch.dart';
import 'package:vortex/src/reactive/store.dart';

/// A class that provides hooks for stateless widgets
class ReactiveHooks {
  static final ReactiveHooks _instance = ReactiveHooks._internal();
  factory ReactiveHooks() => _instance;
  ReactiveHooks._internal();

  /// Create a reactive reference
  static Ref<T> useRef<T>(String key, T initialValue) {
    return ReactiveStore().getRef<T>(key, initialValue);
  }

  /// Create a reactive object
  static Reactive<T> useReactive<T extends Object>(String key, T initialState) {
    return ReactiveStore().getReactive<T>(key, initialState);
  }

  /// Create a computed value
  static Computed<T> useComputed<T>(
    String key,
    T Function() compute, {
    List<Listenable>? dependencies,
  }) {
    return ReactiveStore().getComputed<T>(key, compute, dependencies: dependencies);
  }

  /// Watch a reactive source
  static Watcher<T> useWatch<T>(
    String key,
    Listenable source,
    T Function() getter,
    void Function(T newValue, T? oldValue) callback, {
    bool immediate = false,
  }) {
    final watcherKey = 'watcher_$key';
    if (ReactiveStore().hasKey(watcherKey)) {
      return ReactiveStore().getWatcher<T>(watcherKey);
    }
    
    final watcher = Watcher<T>(source, getter, callback, immediate: immediate);
    ReactiveStore().setWatcher(watcherKey, watcher);
    return watcher;
  }
}