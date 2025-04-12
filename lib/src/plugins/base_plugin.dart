import 'package:flutter/widgets.dart';
import 'package:vortex/src/plugins/plugin_registry.dart';

/// Base class for FlutterWind plugins
abstract class BasePlugin implements VortexPlugin {
  @override
  Future<void> initialize() async {
    // Default implementation does nothing
  }
  
  @override
  Future<void> onAppStart(BuildContext context) async {
    // Default implementation does nothing
  }
  
  @override
  Future<void> onAppClose() async {
    // Default implementation does nothing
  }
}