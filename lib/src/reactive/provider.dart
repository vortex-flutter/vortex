import 'package:flutter/widgets.dart';
import 'package:vortex/src/reactive/store.dart';

/// A provider for the reactive system
class ReactiveProvider extends InheritedWidget {
  final ReactiveStore store;

  const ReactiveProvider({
    super.key,
    required this.store,
    required super.child,
  });

  static ReactiveProvider of(BuildContext context) {
    final provider = context.dependOnInheritedWidgetOfExactType<ReactiveProvider>();
    assert(provider != null, 'No ReactiveProvider found in context');
    return provider!;
  }

  @override
  bool updateShouldNotify(ReactiveProvider oldWidget) {
    return store != oldWidget.store;
  }
}