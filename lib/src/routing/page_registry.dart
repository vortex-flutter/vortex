import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart';
import 'package:vortex/vortex.dart';
import 'dart:io';
import 'package:path/path.dart' as path;

/// Registry for Vortex page components
class VortexPageRegistry {
  /// Map of route paths to page component builders
  static final Map<String, Widget Function(BuildContext, dynamic)>
      _pageComponents = {};

  // Map of route paths to middleware lists
  static final Map<String, List<String>> _routeMiddleware = {};

  /// Map to track registered routes by file path
  static final Map<String, String> _filePathToRoute = {};

  /// Register a page component
  static void registerPage(
    String routePath,
    Widget Function(BuildContext, dynamic) builder, {
    List<String> middleware = const [],
    String? filePath,
  }) {
    _pageComponents[routePath] = builder;

    // Register middleware for the route
    if (middleware.isNotEmpty) {
      _routeMiddleware[routePath] = List.from(middleware);
    }

    if (filePath != null) {
      _filePathToRoute[filePath] = routePath;
    }
  }

  /// Get middleware for a route
  static List<String> getMiddlewareForRoute(String routePath) {
    // Normalize the path
    final normalizedPath = _normalizePath(routePath);

    // Try exact match first
    if (_routeMiddleware.containsKey(normalizedPath)) {
      return _routeMiddleware[normalizedPath] ?? [];
    }

    // Try to match by path without leading slash
    if (normalizedPath.startsWith('/') && normalizedPath.length > 1) {
      final pathWithoutSlash = normalizedPath.substring(1);
      if (_routeMiddleware.containsKey(pathWithoutSlash)) {
        return _routeMiddleware[pathWithoutSlash] ?? [];
      }
    }

    return [];
  }

  /// Get a page component by route path
  static Widget Function(BuildContext, dynamic)? getPageComponent(
      String routePath) {
    // Normalize the path
    final normalizedPath = _normalizePath(routePath);

    // Try exact match first
    if (_pageComponents.containsKey(normalizedPath)) {
      return _pageComponents[normalizedPath];
    }

    // Special handling for root path
    if (normalizedPath == '/' || normalizedPath.isEmpty) {
      // Try alternative names for root path
      for (final altName in ['index', 'home', 'main']) {
        if (_pageComponents.containsKey(altName)) {
          return _pageComponents[altName];
        }
      }
    }

    // Try to match by path without leading slash
    if (normalizedPath.startsWith('/') && normalizedPath.length > 1) {
      final pathWithoutSlash = normalizedPath.substring(1);
      if (_pageComponents.containsKey(pathWithoutSlash)) {
        return _pageComponents[pathWithoutSlash];
      }
    }

    return null;
  }

  /// Normalize a path for consistent matching
  static String _normalizePath(String path) {
    // Remove trailing slash except for root path
    if (path.length > 1 && path.endsWith('/')) {
      path = path.substring(0, path.length - 1);
    }

    // Ensure root path is represented as '/'
    if (path.isEmpty) {
      path = '/';
    }

    return path;
  }

  /// Find a dynamic route component that matches the given route path
  static Widget Function(BuildContext, dynamic)? findDynamicRouteComponent(
      String routePath) {
    // Extract the pattern from the route path
    final segments = routePath.split('/');

    // Try to find a matching pattern
    for (final entry in _pageComponents.entries) {
      final patternSegments = entry.key.split('/');

      if (patternSegments.length != segments.length) continue;

      bool isMatch = true;
      Map<String, String> params = {};

      for (int i = 0; i < segments.length; i++) {
        final patternSeg = patternSegments[i];
        final routeSeg = segments[i];

        if (patternSeg.startsWith(':')) {
          // This is a parameter segment
          final paramName = patternSeg.substring(1);
          params[paramName] = routeSeg;
        } else if (patternSeg != routeSeg) {
          isMatch = false;
          break;
        }
      }

      if (isMatch) {
        Log.d(
            "Found dynamic route match: $routePath -> ${entry.key} with params: $params");
        return (context, args) {
          // Merge the route parameters with the provided arguments
          final mergedArgs = <String, dynamic>{
            ...params,
            if (args is Map<String, dynamic>) ...args,
          };

          return entry.value(context, mergedArgs);
        };
      }
    }

    return null;
  }

  /// Get route by file path
  static String? getRouteByFilePath(String filePath) {
    return _filePathToRoute[filePath];
  }

  /// Register routes from a directory
  static void registerRoutesFromDirectory(String directoryPath) {
    try {
      final directory = Directory(directoryPath);
      if (!directory.existsSync()) {
        Log.e("Directory does not exist: $directoryPath");
        return;
      }

      // Get all Dart files in the directory
      final files = directory
          .listSync(recursive: true)
          .where((entity) => entity is File && entity.path.endsWith('.dart'))
          .cast<File>();

      for (final file in files) {
        _tryRegisterRouteFromFile(file.path);
      }

      Log.i("Registered routes from directory: $directoryPath");
    } catch (e) {
      Log.e("Error registering routes from directory: $e");
    }
  }

  /// Try to register a route from a file
  static void _tryRegisterRouteFromFile(String filePath) {
    try {
      final file = File(filePath);
      if (!file.existsSync()) return;

      final content = file.readAsStringSync();

      // Look for VortexPage annotation with middleware
      final annotationMatch = RegExp(
              r'''@VortexPage\(\s*(['"])(.*?)\1\s*(?:,\s*middleware\s*:\s*\[(.*?)\])?\s*\)''')
          .firstMatch(content);
      if (annotationMatch != null) {
        final routePath = annotationMatch.group(2)!;
        final middlewareStr = annotationMatch.group(3);
        final fileName = path.basename(filePath);

        // Parse middleware list if present
        List<String> middleware = [];

        if (middlewareStr?.trim().isNotEmpty ?? false) {
          middleware = middlewareStr!
              .split(',')
              .map((m) => m.trim().replaceAll(RegExp(r'''^['"]|['"]$'''), ''))
              .where((m) => m.isNotEmpty)
              .toList();
        }

        // Extract class name
        final classMatch = RegExp(r'class\s+(\w+)\s+extends\s+StatelessWidget')
            .firstMatch(content);
        if (classMatch != null) {
          final className = classMatch.group(1)!;
          Log.i(
              "Found page component in file: $fileName, class: $className, route: $routePath, middleware: $middleware");

          // Register the route with middleware
          _filePathToRoute[filePath] = routePath;
          if (middleware.isNotEmpty) {
            _routeMiddleware[routePath] = middleware;
          }
        }
      }
    } catch (e) {
      Log.e("Error registering route from file: $e");
    }
  }

  /// Clear all registered components (for testing)
  static void clear() {
    _pageComponents.clear();
    _routeMiddleware.clear();
    _filePathToRoute.clear();
  }
}

/// Annotation for Vortex pages
class VortexPage {
  final String routePath;
  final List<String> middleware;

  const VortexPage(this.routePath, {this.middleware = const []});
}
