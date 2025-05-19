import 'package:flutter/widgets.dart';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:vortex/vortex.dart';

/// Registry for FlutterWind components
class ComponentRegistry {
  /// Map of component names to builder functions
  static final Map<String, Widget Function(Map<String, dynamic>)> components =
      {};

  /// Map of component types to instances
  static final Map<Type, dynamic> _typed = {};

  /// Register a component
  static void register<T extends Widget>(
    String name,
    Widget Function(Map<String, dynamic>) builder,
  ) {
    if (components.containsKey(name)) {
      Log.w('Component "$name" is already registered. It will be overwritten.');
    }
    components[name] = builder;
    _typed[T] = builder;
  }

  /// Get a component by name
  static Widget Function(Map<String, dynamic>)? get(String name) {
    return components[name];
  }

  /// Get a component by type
  static T? getByType<T>() => _typed[T] as T?;

  /// Check if a component exists
  static bool has(String name) {
    return components.containsKey(name);
  }

  /// Scan a directory for components
  static void scanDirectory(String directory) {
    try {
      final dir = Directory(directory);
      if (!dir.existsSync()) {
        Log.w('Component directory does not exist: $directory');
        return;
      }

      final entities = dir.listSync(recursive: true);

      for (final entity in entities) {
        if (entity is File && entity.path.endsWith('.dart')) {
          _tryRegisterComponent(entity.path);
        }
      }

      Log.i('Scanned ${entities.length} files for components');
      Log.i('Registered ${components.length} components');
    } catch (e) {
      Log.e('Error scanning for components: $e');
    }
  }

  /// Try to register a component from a file
  static void _tryRegisterComponent(String filePath) {
    try {
      final file = File(filePath);
      final content = file.readAsStringSync();

      // Look for @Component annotation
      final annotationMatch = RegExp(r'@Component\(\s*\)').firstMatch(content);

      if (annotationMatch != null) {
        // Extract class name
        final classMatch = RegExp(
          r'class\s+(\w+)\s+extends\s+StatelessWidget',
        ).firstMatch(content);

        if (classMatch != null) {
          final className = classMatch.group(1)!;
          final fileName = path.basename(filePath);

          Log.i('Found component in file: $fileName, class: $className');

          // We can't dynamically instantiate the class here, but we can register the file path
          // The actual component will be created by the build system
        }
      }
    } catch (e) {
      Log.e('Error registering component from file: $e');
    }
  }
}

/// Annotation for FlutterWind components
class Component {
  const Component();
}
