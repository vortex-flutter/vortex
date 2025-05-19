import 'package:flutter/widgets.dart';
import 'package:vortex/vortex.dart';

/// Base class for accessing Vortex components
class VortexComponent {
  // Singleton instance
  static final VortexComponent instance = VortexComponent._();

  // Private constructor to enforce singleton pattern
  VortexComponent._();

  /// Get a component by type
  static Widget Function(Map<String, dynamic>) use<T extends Widget>() {
    final value = ComponentRegistry.getByType<T>();
    if (value == null) {
      throw Exception('Component of type $T not found');
    }
    return value as Widget Function(Map<String, dynamic>);
  }
}
