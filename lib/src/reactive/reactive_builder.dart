import 'package:flutter/widgets.dart';
/// A builder widget that rebuilds when reactive variables change
class ReactiveBuilder extends StatefulWidget {
  final Widget Function(BuildContext context) builder;
  final List<Listenable> dependencies;

  const ReactiveBuilder({
    super.key,
    required this.builder,
    required this.dependencies,
  });

  @override
  State<ReactiveBuilder> createState() => _ReactiveBuilderState();
}

class _ReactiveBuilderState extends State<ReactiveBuilder> {
  @override
  void initState() {
    super.initState();
    for (final dep in widget.dependencies) {
      dep.addListener(_handleChange);
    }
  }

  @override
  void didUpdateWidget(ReactiveBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Remove old listeners
    for (final dep in oldWidget.dependencies) {
      if (!widget.dependencies.contains(dep)) {
        dep.removeListener(_handleChange);
      }
    }
    
    // Add new listeners
    for (final dep in widget.dependencies) {
      if (!oldWidget.dependencies.contains(dep)) {
        dep.addListener(_handleChange);
      }
    }
  }

  @override
  void dispose() {
    for (final dep in widget.dependencies) {
      dep.removeListener(_handleChange);
    }
    super.dispose();
  }

  void _handleChange() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context);
  }
}