import 'package:flutter/widgets.dart';
import 'package:vortex/src/reactive/composition_mixin.dart';

/// A base class for Vue-like components
abstract class ReactiveComponent extends StatefulWidget {
  const ReactiveComponent({super.key});

  @override
  ReactiveComponentState createState() => ReactiveComponentState();
}

class ReactiveComponentState extends State<ReactiveComponent> with CompositionMixin {
  @override
  Widget build(BuildContext context) {
    return setup(context);
  }

  /// Override this method to set up your component
  Widget setup(BuildContext context) {
    return const SizedBox.shrink();
  }
}