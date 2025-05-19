import 'package:meta/meta.dart';

/// Annotation for Vortex plugins
@immutable
class VortexPlugin {
  /// The name of the plugin
  final String name;
  
  /// Constructor
  const VortexPlugin(this.name);
}