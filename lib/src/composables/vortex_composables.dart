import 'package:vortex/vortex.dart';

/// Base class for accessing Vortex composables
class VortexComposables {
  // Singleton instance
  static final VortexComposables instance = VortexComposables._();
  
  // Private constructor to enforce singleton pattern
  VortexComposables._();
  
  /// Get a composable by name
  static T use<T>() {
		final value = ComposableRegistry.getByType(T);
		if (value == null) {
			throw Exception('Composable of type $T not found');
		}
		return value as T;
	}
}