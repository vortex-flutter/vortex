import 'package:flutter/widgets.dart';

/// A registry for lifecycle hooks
class LifecycleHooks {
  static final Map<BuildContext, List<VoidCallback>> _beforeMountCallbacks = {};
  static final Map<BuildContext, List<VoidCallback>> _mountedCallbacks = {};
  static final Map<BuildContext, List<VoidCallback>> _beforeUpdateCallbacks = {};
  static final Map<BuildContext, List<VoidCallback>> _updatedCallbacks = {};
  static final Map<BuildContext, List<VoidCallback>> _beforeUnmountCallbacks = {};
  static final Map<BuildContext, List<VoidCallback>> _unmountedCallbacks = {};

  /// Register a callback to be called before the widget is mounted
  static void onBeforeMount(BuildContext context, VoidCallback callback) {
    _beforeMountCallbacks.putIfAbsent(context, () => []).add(callback);
  }

  /// Register a callback to be called after the widget is mounted
  static void onMounted(BuildContext context, VoidCallback callback) {
    _mountedCallbacks.putIfAbsent(context, () => []).add(callback);
  }

  /// Register a callback to be called before the widget is updated
  static void onBeforeUpdate(BuildContext context, VoidCallback callback) {
    _beforeUpdateCallbacks.putIfAbsent(context, () => []).add(callback);
  }

  /// Register a callback to be called after the widget is updated
  static void onUpdated(BuildContext context, VoidCallback callback) {
    _updatedCallbacks.putIfAbsent(context, () => []).add(callback);
  }

  /// Register a callback to be called before the widget is unmounted
  static void onBeforeUnmount(BuildContext context, VoidCallback callback) {
    _beforeUnmountCallbacks.putIfAbsent(context, () => []).add(callback);
  }

  /// Register a callback to be called after the widget is unmounted
  static void onUnmounted(BuildContext context, VoidCallback callback) {
    _unmountedCallbacks.putIfAbsent(context, () => []).add(callback);
  }

  /// Trigger before mount callbacks
  static void triggerBeforeMount(BuildContext context) {
    _beforeMountCallbacks[context]?.forEach((callback) => callback());
  }

  /// Trigger mounted callbacks
  static void triggerMounted(BuildContext context) {
    _mountedCallbacks[context]?.forEach((callback) => callback());
  }

  /// Trigger before update callbacks
  static void triggerBeforeUpdate(BuildContext context) {
    _beforeUpdateCallbacks[context]?.forEach((callback) => callback());
  }

  /// Trigger updated callbacks
  static void triggerUpdated(BuildContext context) {
    _updatedCallbacks[context]?.forEach((callback) => callback());
  }

  /// Trigger before unmount callbacks
  static void triggerBeforeUnmount(BuildContext context) {
    _beforeUnmountCallbacks[context]?.forEach((callback) => callback());
  }

  /// Trigger unmounted callbacks
  static void triggerUnmounted(BuildContext context) {
    _unmountedCallbacks[context]?.forEach((callback) => callback());
    
    // Clean up callbacks for this context
    _beforeMountCallbacks.remove(context);
    _mountedCallbacks.remove(context);
    _beforeUpdateCallbacks.remove(context);
    _updatedCallbacks.remove(context);
    _beforeUnmountCallbacks.remove(context);
    _unmountedCallbacks.remove(context);
  }
}