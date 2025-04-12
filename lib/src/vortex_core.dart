import 'dart:io';

import 'package:flutter/widgets.dart';
import '../vortex.dart';

class Vortex extends StatefulWidget {
  final Widget child;

  const Vortex({super.key, required this.child});

  /// Initialize FlutterWind framework
  static Future<void> initialize({Directory? projectDirectory}) async {
    try {
      // Discover plugins
      await PluginRegistry.discoverPlugins(projectDirectory: projectDirectory);

      // Initialize plugins
      await PluginRegistry.initializePlugins();

      Log.i('FlutterWind initialized successfully');
    } catch (e, stackTrace) {
      Log.e('Error initializing FlutterWind', e, stackTrace);
    }
  }

  /// Notify plugins that the app has started
  static Future<void> notifyAppStart(BuildContext context) async {
    try {
      await PluginRegistry.notifyAppStart(context);
    } catch (e) {
      Log.e('Error notifying plugins of app start: $e');
    }
  }

  /// Notify plugins that the app is closing
  static Future<void> notifyAppClose() async {
    try {
      await PluginRegistry.notifyAppClose();
    } catch (e) {
      Log.e('Error notifying plugins of app close: $e');
    }
  }

  @override
  State<Vortex> createState() => _VortexState();
}

class _VortexState extends State<Vortex> with WidgetsBindingObserver {
  final ReactiveStore _reactiveStore = ReactiveStore();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Notify plugins of app start after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Vortex.notifyAppStart(context);
    });
  }

  @override
  void dispose() {
    // Notify plugins of app close
    Vortex.notifyAppClose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ReactiveProvider(
      store: _reactiveStore,
      child: VortexComponentProvider(
        components: ComponentRegistry.components,
        child: widget.child,
      ),
    );
  }
}
