import 'package:vortex/vortex.dart';

class VortexPlugins {
  const VortexPlugins();

  static final instance = VortexPlugins();
  
  static T use<T extends Plugin>() {
    final plugin = PluginRegistry.plugins.firstWhere((p) => p is T, orElse: () {
      throw Exception('Plugin of type $T not found');
    });
    return plugin as T;
  }
}
