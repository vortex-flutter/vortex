import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:vortex/vortex.dart';
import 'package:path/path.dart' as path;

/// A plugin for Vortex
abstract class Plugin {
  /// The name of the plugin
  String get name;

  /// When to run the plugin: 'pre', 'normal', or 'post'
  final String enforce;

  /// Whether to run the plugin in parallel with others
  final bool parallel;

  /// List of plugin names this plugin depends on
  final List<String> dependsOn;

  /// The setup function for the plugin
  final Future<Map<String, dynamic>> Function(Vortex app) setup;

  /// Constructor to initialize the required fields
  Plugin({
    required this.enforce,
    required this.parallel,
    required this.dependsOn,
    required this.setup,
  });

  /// Initialize the plugin
  Future<void> initialize();

  /// Called when the app is starting
  Future<void> onAppStart(BuildContext context);

  /// Called when the app is about to close
  Future<void> onAppClose();

  /// Get a helper provided by this plugin
  dynamic getHelper(String name);

  /// Check if this plugin provides a helper
  bool hasHelper(String name);

  /// Get all helpers provided by this plugin
  Map<String, dynamic> get helpers;

  /// Called when a plugin this plugin depends on is initialized
  Future<void> onDependencyInitialized(String pluginName) async {}

  /// Called when a plugin this plugin depends on fails to initialize
  Future<void> onDependencyFailed(String pluginName, dynamic error) async {}

  /// Called when the plugin is about to be unloaded
  Future<void> onUnload() async {}
}

/// Registry for Vortex plugins
class PluginRegistry {
  static final Map<String, Plugin> _plugins = {};
  static final Map<String, bool> _initialized = {};
  static final Map<String, dynamic> _pluginConfigs = {};

  /// Register a plugin
  static void register(Plugin plugin) {
    if (_plugins.containsKey(plugin.name)) {
      throw Exception('Plugin already registered: ${plugin.name}');
    }
    _plugins[plugin.name] = plugin;
    _initialized[plugin.name] = false;
  }

  /// Get a plugin by name
  static Plugin? getPlugin(String name) {
    return _plugins[name];
  }

  /// Get all registered plugins
  static List<Plugin> get plugins => _plugins.values.toList();

  /// Initialize all plugins
  static Future<void> initializePlugins() async {
    final prePlugins =
        _plugins.values.where((p) => p.enforce == 'pre').toList();
    final normalPlugins =
        _plugins.values.where((p) => p.enforce == 'normal').toList();
    final postPlugins =
        _plugins.values.where((p) => p.enforce == 'post').toList();

    // Initialize pre plugins
    for (final plugin in prePlugins) {
      await _initializePlugin(plugin);
    }

    // Initialize normal plugins
    for (final plugin in normalPlugins) {
      await _initializePlugin(plugin);
    }

    // Initialize post plugins
    for (final plugin in postPlugins) {
      await _initializePlugin(plugin);
    }
  }

  /// Initialize a single plugin
  static Future<void> _initializePlugin(Plugin plugin) async {
    if (_initialized[plugin.name] == true) return;

    // Check dependencies
    for (final depName in plugin.dependsOn) {
      final dep = _plugins[depName];
      if (dep == null) {
        throw Exception(
          'Dependency not found: $depName for plugin ${plugin.name}',
        );
      }

      if (_initialized[depName] != true) {
        try {
          await _initializePlugin(dep);
        } catch (e) {
          await plugin.onDependencyFailed(depName, e);
          rethrow;
        }
      }
      await plugin.onDependencyInitialized(depName);
    }

    try {
      await plugin.initialize();
      _initialized[plugin.name] = true;
      Log.i('Plugin initialized: ${plugin.name}');
    } catch (e) {
      Log.e('Failed to initialize plugin: ${plugin.name}', e);
      rethrow;
    }
  }

  /// Discover plugins in a directory
  static Future<void> discoverPlugins({Directory? projectDirectory}) async {
    final dir = projectDirectory ?? Directory.current;
    final pluginDir = Directory(path.join(dir.path, 'lib', 'plugins'));

    if (!await pluginDir.exists()) {
      Log.w('Plugin directory not found: ${pluginDir.path}');
      return;
    }

    final files = await pluginDir.list(recursive: true).toList();
    for (final file in files) {
      if (file is File && file.path.endsWith('.dart')) {
        try {
          // TODO: Implement plugin discovery from files
          // This would require reflection or code generation
          Log.i('Found potential plugin file: ${file.path}');
        } catch (e) {
          Log.e('Error discovering plugin from file: ${file.path}', e);
        }
      }
    }
  }

  /// Notify plugins of app start
  static Future<void> notifyAppStart(BuildContext context) async {
    for (final plugin in _plugins.values) {
      try {
        await plugin.onAppStart(context);
      } catch (e) {
        Log.e('Error in plugin ${plugin.name} onAppStart', e);
      }
    }
  }

  /// Notify plugins of app close
  static Future<void> notifyAppClose() async {
    for (final plugin in _plugins.values) {
      try {
        await plugin.onAppClose();
      } catch (e) {
        Log.e('Error in plugin ${plugin.name} onAppClose', e);
      }
    }
  }

  /// Unload a plugin
  static Future<void> unloadPlugin(String name) async {
    final plugin = _plugins[name];
    if (plugin == null) {
      throw Exception('Plugin not found: $name');
    }

    try {
      await plugin.onUnload();
      _plugins.remove(name);
      _initialized.remove(name);
      _pluginConfigs.remove(name);
      Log.i('Plugin unloaded: $name');
    } catch (e) {
      Log.e('Error unloading plugin: $name', e);
      rethrow;
    }
  }

  /// Get plugin configuration
  static dynamic getPluginConfig(String pluginName) {
    return _pluginConfigs[pluginName];
  }

  /// Set plugin configuration
  static void setPluginConfig(String pluginName, dynamic config) {
    _pluginConfigs[pluginName] = config;
  }
}
