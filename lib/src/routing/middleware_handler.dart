import 'package:flutter/widgets.dart';
import 'package:vortex/vortex.dart';
import 'package:vortex/src/middleware/middleware_registry.dart';

/// Handler for middleware in the router
class MiddlewareHandler {
  /// Execute middleware for a route
  static Future<bool> handle(
      BuildContext context, String route, List<String> middlewareNames) async {
    Log.i("VortexMiddleware: Executing middleware for route: $route");
    if (middlewareNames.isEmpty) {
      return true;
    }

    for (final name in middlewareNames) {
      final middleware = MiddlewareRegistry.get(name);
      if (middleware == null) {
        throw Exception('VortexMiddleware: Middleware not found: $name');
      }

      final result = await middleware.execute(context, route);
      if (!result) {
        // If any middleware returns false, stop the chain and prevent navigation
        return false;
      }
    }

    // All middleware passed
    return true;
  }
}
