import 'package:meta/meta.dart';

/// Annotation for FlutterWind pages
@immutable
class VortexPage {
  final String route;
  final List<String> middleware;
  
  const VortexPage(this.route, {this.middleware = const []});
}