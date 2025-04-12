import 'package:flutter/widgets.dart';
import 'package:vortex/src/middleware/middleware.dart';

/// Registry for FlutterWind middleware
class MiddlewareRegistry {
  /// Map of middleware names to middleware instances
  static final Map<String, VortexMiddleware> _middleware = {};

  /// Register a middleware
  static void register(String name, VortexMiddleware middleware) {
    _middleware[name] = middleware;
  }

  /// Get a middleware by name
  static VortexMiddleware? get(String name) {
    return _middleware[name];
  }

  /// Check if a middleware exists
  static bool has(String name) {
    return _middleware.containsKey(name);
  }

  /// Execute all middleware for a route
  static Future<bool> executeAll(
      BuildContext context, String route, List<String> middlewareNames) async {
    for (final name in middlewareNames) {
      final middleware = get(name);
      if (middleware == null) {
        throw Exception('Middleware not found: $name');
      }

      final result = await middleware.execute(context, route);
      if (!result) {
        return false;
      }
    }

    return true;
  }
}
