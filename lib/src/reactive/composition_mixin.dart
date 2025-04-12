import 'package:flutter/widgets.dart';
import 'package:vortex/src/reactive/lifecycle.dart';
import 'package:vortex/src/reactive/ref.dart';
import 'package:vortex/src/reactive/reactive.dart';
import 'package:vortex/src/reactive/computed.dart';
import 'package:vortex/src/reactive/watch.dart';
import 'package:vortex/src/reactive/store.dart';

/// A mixin that provides Vue-like composition API to Flutter widgets
mixin CompositionMixin<T extends StatefulWidget> on State<T> {
  final List<Listenable> _reactiveVariables = [];
  final List<Watcher> _watchers = [];

  /// Create a reactive reference
  Ref<V> ref<V>(V initialValue) {
    final refVar = Ref<V>(initialValue);
    _reactiveVariables.add(refVar);
    refVar.addListener(_reactiveUpdate);
    return refVar;
  }

  /// Create a reactive object
  Reactive<V> reactive<V extends Object>(V initialState) {
    final reactiveVar = Reactive<V>(initialState);
    _reactiveVariables.add(reactiveVar);
    reactiveVar.addListener(_reactiveUpdate);
    return reactiveVar;
  }

  /// Create a computed value
  Computed<V> computed<V>(V Function() compute, {List<Listenable>? dependencies}) {
    final computedVar = Computed<V>(compute);
    if (dependencies != null) {
      for (final dep in dependencies) {
        computedVar.addDependency(dep);
      }
    }
    _reactiveVariables.add(computedVar);
    computedVar.addListener(_reactiveUpdate);
    return computedVar;
  }

  /// Watch a reactive source
  Watcher<V> watch<V>(
    Listenable source,
    V Function() getter,
    void Function(V newValue, V? oldValue) callback, {
    bool immediate = false,
  }) {
    final watcher = Watcher<V>(source, getter, callback, immediate: immediate);
    _watchers.add(watcher);
    return watcher;
  }

  /// Register a callback to be called before the widget is mounted
  void onBeforeMount(VoidCallback callback) {
    LifecycleHooks.onBeforeMount(context, callback);
  }

  /// Register a callback to be called after the widget is mounted
  void onMounted(VoidCallback callback) {
    LifecycleHooks.onMounted(context, callback);
  }

  /// Register a callback to be called before the widget is updated
  void onBeforeUpdate(VoidCallback callback) {
    LifecycleHooks.onBeforeUpdate(context, callback);
  }

  /// Register a callback to be called after the widget is updated
  void onUpdated(VoidCallback callback) {
    LifecycleHooks.onUpdated(context, callback);
  }

  /// Register a callback to be called before the widget is unmounted
  void onBeforeUnmount(VoidCallback callback) {
    LifecycleHooks.onBeforeUnmount(context, callback);
  }

  /// Register a callback to be called after the widget is unmounted
  void onUnmounted(VoidCallback callback) {
    LifecycleHooks.onUnmounted(context, callback);
  }

  /// Get a global reactive reference
  Ref<V> useRef<V>(String key, V initialValue) {
    final ref = ReactiveStore().getRef<V>(key, initialValue);
    ref.addListener(_reactiveUpdate);
    return ref;
  }

  /// Get a global reactive object
  Reactive<V> useReactive<V extends Object>(String key, V initialState) {
    final reactive = ReactiveStore().getReactive<V>(key, initialState);
    reactive.addListener(_reactiveUpdate);
    return reactive;
  }

  /// Get a global computed value
  Computed<V> useComputed<V>(
    String key,
    V Function() compute, {
    List<Listenable>? dependencies,
  }) {
    final computed = ReactiveStore().getComputed<V>(key, compute, dependencies: dependencies);
    computed.addListener(_reactiveUpdate);
    return computed;
  }

  @override
  void initState() {
    super.initState();
    LifecycleHooks.triggerBeforeMount(context);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        LifecycleHooks.triggerMounted(context);
      }
    });
  }

  @override
  void didUpdateWidget(covariant T oldWidget) {
    super.didUpdateWidget(oldWidget);
    LifecycleHooks.triggerBeforeUpdate(context);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        LifecycleHooks.triggerUpdated(context);
      }
    });
  }

  @override
  void dispose() {
    LifecycleHooks.triggerBeforeUnmount(context);
    
    // Remove listeners from all reactive variables
    for (final variable in _reactiveVariables) {
      variable.removeListener(_reactiveUpdate);
    }
    
    // Stop all watchers
    for (final watcher in _watchers) {
      watcher.stop();
    }
    
    LifecycleHooks.triggerUnmounted(context);
    super.dispose();
  }

  void _reactiveUpdate() {
    if (mounted) {
      setState(() {});
    }
  }
}