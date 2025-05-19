import 'package:flutter/widgets.dart';
import 'package:vortex/src/plugins/plugin_registry.dart';

/// A dependency injection container for Vortex plugins
/// 
/// This class provides a centralized way to manage plugin dependencies,
/// configuration, and services. It allows plugins to register and retrieve
/// services, making it easier to share functionality between plugins.
class PluginContainer {
  static final PluginContainer _instance = PluginContainer._internal();
  
  /// Get the singleton instance
  static PluginContainer get instance => _instance;
  
  /// Services registered with the container
  final Map<String, dynamic> _services = {};
  
  /// Service factories for lazy initialization
  final Map<String, Function> _factories = {};
  
  /// Service singletons
  final Map<String, dynamic> _singletons = {};
  
  /// Private constructor
  PluginContainer._internal();
  
  /// Register a service with the container
  void register<T>(String name, T service) {
    _services[name] = service;
  }
  
  /// Register a factory function that creates a service on demand
  void factory<T>(String name, T Function() factory) {
    _factories[name] = factory;
  }
  
  /// Register a singleton service that is created only once when first requested
  void singleton<T>(String name, T Function() factory) {
    _factories[name] = factory;
  }
  
  /// Get a service from the container
  T? get<T>(String name) {
    // Check if service exists
    if (_services.containsKey(name)) {
      return _services[name] as T;
    }
    
    // Check if singleton exists
    if (_singletons.containsKey(name)) {
      return _singletons[name] as T;
    }
    
    // Check if factory exists
    if (_factories.containsKey(name)) {
      final factory = _factories[name]!;
      final service = factory() as T;
      
      // If this is a singleton, store the instance
      if (_factories.containsKey(name) && !_services.containsKey(name)) {
        _singletons[name] = service;
      }
      
      return service;
    }
    
    return null;
  }
  
  /// Check if a service exists in the container
  bool has(String name) {
    return _services.containsKey(name) || 
           _factories.containsKey(name) || 
           _singletons.containsKey(name);
  }
  
  /// Remove a service from the container
  void remove(String name) {
    _services.remove(name);
    _factories.remove(name);
    _singletons.remove(name);
  }
  
  /// Clear all services from the container
  void clear() {
    _services.clear();
    _factories.clear();
    _singletons.clear();
  }
}

/// Extension methods for Plugin to interact with the container
extension PluginContainerExtension on Plugin {
  /// Get a service from the container
  T? getService<T>(String name) {
    return PluginContainer.instance.get<T>(name);
  }
  
  /// Register a service with the container
  void registerService<T>(String name, T service) {
    PluginContainer.instance.register<T>(name, service);
  }
  
  /// Check if a service exists in the container
  bool hasService(String name) {
    return PluginContainer.instance.has(name);
  }
}