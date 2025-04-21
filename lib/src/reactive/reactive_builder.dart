import 'package:flutter/widgets.dart';
import 'package:flutter/scheduler.dart';

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
  bool _needsBuild = false;

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
      // Instead of calling setState directly, schedule it for the next frame
      // to avoid calling setState during build
      if (SchedulerBinding.instance.schedulerPhase == SchedulerPhase.idle) {
        setState(() {
          _needsBuild = false;
        });
      } else {
        _needsBuild = true;
        SchedulerBinding.instance.addPostFrameCallback((_) {
          if (mounted && _needsBuild) {
            setState(() {
              _needsBuild = false;
            });
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context);
  }
}
