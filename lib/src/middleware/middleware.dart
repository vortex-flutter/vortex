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