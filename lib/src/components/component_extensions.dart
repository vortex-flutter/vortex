import 'package:flutter/widgets.dart';
import 'package:vortex/src/components/component_provider.dart';

/// Extension methods for BuildContext to support auto-importing components
extension ComponentExtensions on BuildContext {
  /// Get a component by name
  dynamic component(String name) {
    final provider = VortexComponentProvider.of(this);
    
    if (provider == null) {
      throw Exception('component() must be used within a FlutterWindComponentProvider');
    }
    
    final builder = provider.components[name];
    
    if (builder == null) {
      throw Exception('Component not found: $name');
    }
    
    return ({Map<String, dynamic> props = const {}}) {
      return builder(props);
    };
  }
}