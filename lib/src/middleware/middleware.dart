import 'package:flutter/widgets.dart';

/// Annotation for FlutterWind middleware
@immutable
class Middleware {
  final String? name;
  const Middleware({this.name});
}

/// Base class for all middleware
abstract class VortexMiddleware {
  /// Execute the middleware
  Future<bool> execute(BuildContext context, String route);
}

/// Route guard interface for fine-grained navigation control
abstract class RouteGuard {
  /// Check if navigation should be allowed
  Future<bool> canActivate(BuildContext context, String route);

  /// Handle navigation failure
  Future<void> onFailure(BuildContext context, String route) async {}
}

/// Navigation lifecycle hooks
mixin NavigationLifecycle {
  /// Called when the route is about to be entered
  Future<void> onBeforeEnter(BuildContext context) async {}

  /// Called when the route has been entered
  Future<void> onAfterEnter(BuildContext context) async {}

  /// Called when the route is about to be left
  Future<bool> onBeforeLeave(BuildContext context) async => true;

  /// Called when navigation is cancelled
  Future<void> onNavigationCancelled(BuildContext context) async {}

  /// Called when an error occurs during navigation
  Future<void> onNavigationError(BuildContext context, dynamic error) async {}
}
