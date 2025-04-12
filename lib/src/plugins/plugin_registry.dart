import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:vortex/vortex.dart';
import 'package:path/path.dart' as path;

/// A plugin for FlutterWind
abstract class VortexPlugin {
  /// The name of the plugin
  String get name;
  
  /// Initialize the plugin
  Future<void> initialize();
  
  /// Called when the app is starting
  Future<void> onAppStart(BuildContext context);
  
  /// Called when the app is about to close
  Future<void> onAppClose();
}

/// Registry for FlutterWind plugins
class PluginRegistry {
  static final Map<String, VortexPlugin> _plugins = {};
  static bool _pluginsDiscovered = false;
  static final List<String> _possiblePluginDirectories = [
    'lib/plugins',
    'example/lib/plugins',
    'lib/src/plugins',
    'example/lib/src/plugins',
  ];
  
  /// Register a plugin with the registry
  static void register(VortexPlugin plugin) {
    _plugins[plugin.name] = plugin;
    Log.i('Registered plugin: ${plugin.name}');
  }
  
  /// Get a plugin by name
  static VortexPlugin? getPlugin(String name) {
    return _plugins[name];
  }
  
  /// Check if a plugin is registered
  static bool hasPlugin(String name) {
    return _plugins.containsKey(name);
  }
  
  /// Get all registered plugins
  static List<VortexPlugin> get plugins => _plugins.values.toList();
  
  /// Initialize all registered plugins
  static Future<void> initializePlugins() async {
    for (final plugin in _plugins.values) {
      try {
        Log.i('Initializing plugin: ${plugin.name}');
        await plugin.initialize();
      } catch (e) {
        Log.e('Error initializing plugin ${plugin.name}: $e');
      }
    }
  }
  
  /// Notify all plugins that the app is starting
  static Future<void> notifyAppStart(BuildContext context) async {
    for (final plugin in _plugins.values) {
      try {
        await plugin.onAppStart(context);
      } catch (e) {
        Log.e('Error in plugin ${plugin.name} onAppStart: $e');
      }
    }
  }
  
  /// Notify all plugins that the app is closing
  static Future<void> notifyAppClose() async {
    for (final plugin in _plugins.values) {
      try {
        await plugin.onAppClose();
      } catch (e) {
        Log.e('Error in plugin ${plugin.name} onAppClose: $e');
      }
    }
  }
  
  /// Discover plugins from the file system
  static Future<void> discoverPlugins({Directory? projectDirectory}) async {
    if (_pluginsDiscovered) return;
    
    try {
      // Skip file system operations on web
      if (kIsWeb) {
        Log.w("Running on web platform. File-based plugin discovery is not supported.");
        _pluginsDiscovered = true;
        return;
      }
      
      bool foundPlugins = false;
      
      // Use the provided project directory or find it dynamically
      Directory projectDir;
      if (projectDirectory != null) {
        projectDir = projectDirectory;
      } else {
        // Get the current working directory
        final currentDir = Directory.current;
        projectDir = await _findProjectRoot(currentDir);
      }
      
      // Try each possible plugins directory
      for (final dirPath in _possiblePluginDirectories) {
        final dir = Directory(path.join(projectDir.path, dirPath));
        
        try {
          if (await dir.exists()) {
            await _scanPluginsDirectory(dir);
            foundPlugins = true;
            break;
          }
        } catch (e) {
          Log.e("Error checking directory $dirPath: $e");
        }
      }
      
      if (!foundPlugins) {
        Log.i("No plugins directory found. Checked: ${_possiblePluginDirectories.join(', ')}");
      }
      
      _pluginsDiscovered = true;
    } catch (e, stackTrace) {
      Log.e('FlutterWind: Error discovering plugins: $e');
      Log.d('Stack trace: $stackTrace');
      _pluginsDiscovered = true;
    }
  }
  
  /// Find the project root directory by looking for pubspec.yaml
  static Future<Directory> _findProjectRoot(Directory startDir) async {
    Directory currentDir = startDir;
    
    // Try to find pubspec.yaml in the current directory or its parents
    for (int i = 0; i < 5; i++) {
      // Limit search depth to prevent infinite loops
      final pubspecFile = File(path.join(currentDir.path, 'pubspec.yaml'));
      
      try {
        if (await pubspecFile.exists()) {
          return currentDir;
        }
      } catch (e) {
        Log.e("Error checking for pubspec.yaml: $e");
      }
      
      // Move up one directory
      final parentDir = Directory(path.dirname(currentDir.path));
      if (parentDir.path == currentDir.path) {
        // We've reached the root directory
        break;
      }
      currentDir = parentDir;
    }
    
    // If we couldn't find the project root, return the starting directory
    return startDir;
  }
  
  /// Scan a directory for plugin files
  static Future<void> _scanPluginsDirectory(Directory directory) async {
    try {
      final entities = await directory.list(recursive: true).toList();
      
      for (final entity in entities) {
        if (entity is File && entity.path.endsWith('.dart')) {
          final fileName = path.basename(entity.path);
          if (!fileName.startsWith('_') && !fileName.startsWith('.')) {
            // Register this file as a potential plugin
            Log.d('Found potential plugin file: ${entity.path}');
            
            // Here we would ideally dynamically load the plugin
            // Since Dart doesn't support runtime code loading like JavaScript,
            // we'll rely on the @Plugin annotation in the actual files
          }
        }
      }
    } catch (e) {
      Log.e("Error scanning plugins directory ${directory.path}: $e");
    }
  }
  
  /// Reset the registry (for testing)
  static void reset() {
    _plugins.clear();
    _pluginsDiscovered = false;
  }
}