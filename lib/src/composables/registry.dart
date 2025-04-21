import 'package:vortex/src/utils/logger.dart';

/// A registry for custom composables
class ComposableRegistry {
  static final Map<String, dynamic> _composables = {};
  
  /// Register a custom composable
  static void register(String name, dynamic composable) {
    if (_composables.containsKey(name)) {
      Log.w('Composable "$name" is already registered. It will be overwritten.');
    }
    
    _composables[name] = composable;
  }
  
  /// Get a registered composable
  static dynamic get(String name) {
    if (!_composables.containsKey(name)) {
      Log.e('Composable "$name" is not registered.');
      return null;
    }
    
    return _composables[name];
  }
  
  /// Check if a composable is registered
  static bool has(String name) {
    return _composables.containsKey(name);
  }
  
  /// Remove a registered composable
  static void remove(String name) {
    if (_composables.containsKey(name)) {
      _composables.remove(name);
      Log.i('Removed composable: $name');
    }
  }
  
  /// Get all registered composables
  static Map<String, dynamic> getAll() {
    return Map.from(_composables);
  }
}