import 'dart:io'
    if (dart.library.html) 'package:vortex/src/routing/web_stub.dart';
import 'package:flutter/material.dart';
import 'package:vortex/vortex.dart';
import 'package:vortex/src/routing/middleware_handler.dart';
import 'package:vortex/src/routing/page_registry.dart';
import 'package:path/path.dart' as path;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:async';
import 'package:vortex/src/middleware/middleware.dart';
import 'package:vortex/src/plugins/plugin_registry.dart';

/// VortexRouter handles automatic route discovery and navigation
/// based on the file system structure in the pages directory.
class VortexRouter {
  static final Map<String, WidgetBuilder> _routes = {};
  static bool _routesDiscovered = false;
  static final List<String> _possiblePageDirectories = [
    'lib/pages',
    'example/lib/pages',
    'lib/src/pages',
    'example/lib/src/pages',
  ];
  static Directory? _projectDirectory;

  /// Map to store layout components for routes
  static final Map<String, Widget Function(Widget)> _layouts = {};

  /// Register a route with the router
  static void registerRoute(String routePath, WidgetBuilder builder) {
    _routes[routePath] = builder;
  }

  /// Register multiple routes at once
  static void registerRoutes(Map<String, WidgetBuilder> routes) {
    _routes.addAll(routes);
  }

  /// Register the home page manually
  static void registerHomePage(WidgetBuilder builder) {
    _routes['/'] = builder;
  }

  /// Automatically discover and register routes based on file structure
  static Future<void> discoverRoutes({
    required Directory projectDirectory,
  }) async {
    print(
      'VortexRouter: Discovering routes for project directory: $projectDirectory',
    );
    _projectDirectory = projectDirectory;
    if (_routesDiscovered) return;

    try {
      // Skip file system operations on web
      if (kIsWeb) {
        Log.w(
          "Running on web platform. File-based route discovery is not supported.",
        );
        Log.w(
          "Please register routes manually using registerRoute() or registerRoutes().",
        );

        // Register default home route
        _routes['/'] = (context) => const _DefaultHomePage();
        _routesDiscovered = true;
        return;
      }

      bool foundPages = false;

      // Use the provided project directory or find it dynamically
      Directory projectDir;

      if (_projectDirectory != null) {
        projectDir = _projectDirectory!;
      } else {
        // Get the current working directory
        final currentDir = Directory.current;
        projectDir = await _findProjectRoot(currentDir);
      }

      // Try each possible pages directory
      for (final dirPath in _possiblePageDirectories) {
        final dir = Directory(path.join(projectDir.path, dirPath));

        try {
          if (await dir.exists()) {
            await _scanDirectory(dir, '');
            foundPages = true;
            break;
          }
        } catch (e) {
          Log.e("Error checking directory $dirPath: $e");
        }
      }

      if (!foundPages) {
        Log.e(
          "No pages directory found. Checked: ${_possiblePageDirectories.join(', ')}",
        );
      }

      // Register default home route if not found
      if (_routes.isEmpty || !_routes.containsKey('/')) {
        Log.i("No root route found, registering default home page");
        _routes['/'] = (context) => const _DefaultHomePage();
      }

      _routesDiscovered = true;
    } catch (e, stackTrace) {
      Log.e('VortexRouter: Error discovering routes: $e');
      Log.d('Stack trace: $stackTrace');

      // Register fallback route
      _routes['/'] = (context) => const _DefaultHomePage();
      _routesDiscovered = true;
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

  /// Scan a directory for route files
  static Future<void> _scanDirectory(
    Directory directory,
    String currentPath,
  ) async {
    try {
      final entities = await directory.list().toList();

      // Process directories first to ensure proper ordering
      for (final entity in entities.whereType<Directory>()) {
        final dirName = path.basename(entity.path);
        if (!dirName.startsWith('_') && !dirName.startsWith('.')) {
          final newPath =
              currentPath.isEmpty ? '/$dirName' : '$currentPath/$dirName';
          await _scanDirectory(entity, newPath);
        }
      }

      // Then process files
      for (final entity in entities.whereType<File>()) {
        final fileName = path.basename(entity.path);
        if (fileName.endsWith('.dart') &&
            !fileName.startsWith('_') &&
            !fileName.startsWith('.')) {
          final routePath = _fileNameToRoutePath(fileName, currentPath);

          // Register the route with a dynamic import builder
          _routes[routePath] =
              (context) => _loadPageComponent(context, entity.path, routePath);
        }
      }
    } catch (e) {
      Log.e("Error scanning directory ${directory.path}: $e");
    }
  }

  /// Convert a file name to a route path
  static String _fileNameToRoutePath(String fileName, String currentPath) {
    final baseName = fileName.replaceAll('.dart', '');

    // Handle index files
    if (baseName == 'index') {
      return currentPath.isEmpty ? '/' : currentPath;
    }

    // Handle dynamic route parameters [id].dart -> :id
    String routeSegment = baseName;
    if (baseName.startsWith('[') && baseName.endsWith(']')) {
      routeSegment = ':${baseName.substring(1, baseName.length - 1)}';
    }

    return currentPath.isEmpty
        ? '/$routeSegment'
        : '$currentPath/$routeSegment';
  }

  // Add this to the VortexRouter class
  static final Map<String, Type> _pageComponentTypes = {};
  static final Map<String, dynamic Function()> _pageFactories = {};

  /// Register a page component type with the router
  static void registerPageComponentType(String routePath, Type componentType) {
    _pageComponentTypes[routePath] = componentType;
  }

  /// Register a page factory function with the router
  static void registerPageFactory(
    String routePath,
    dynamic Function() factory,
  ) {
    _pageFactories[routePath] = factory;
  }

  /// Load the actual page component from a file
  static Widget _loadPageComponent(
    BuildContext context,
    String filePath,
    String routePath,
  ) {
    try {
      // Get route parameters
      final routeSettings = ModalRoute.of(context)?.settings;
      final routeArgs = routeSettings?.arguments;

      // Try to determine the import path for this file
      _filePathToImportPath(filePath);

      // First try to use a registered factory function
      if (_pageFactories.containsKey(routePath)) {
        final factory = _pageFactories[routePath]!;
        final instance = factory();

        if (instance is Widget) {
          return instance;
        } else if (instance is WidgetBuilder) {
          return instance(context);
        } else {
          Log.w(
            "Factory for $routePath returned invalid type: ${instance.runtimeType}",
          );
        }
      }

      // Try to use a registered component type
      if (_pageComponentTypes.containsKey(routePath)) {
        final type = _pageComponentTypes[routePath]!;

        // Try to create an instance using reflection
        try {
          // This is a simplified approach - in a real implementation,
          // you would use a more robust reflection mechanism
          return _createWidgetFromType(type, context, routeArgs);
        } catch (e) {
          Log.e("Error creating widget from type $type: $e");
        }
      }

      // Try to load the component dynamically
      final component = _loadComponentDynamically(
        filePath,
        routePath,
        context,
        routeArgs,
      );
      if (component != null) {
        return component;
      }

      // If all else fails, show a placeholder with instructions
      return Scaffold(
        appBar: AppBar(title: Text('Route: $routePath')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Dynamic Loading',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(height: 20),
              Text('Route: $routePath', style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 10),
              Text(
                'File: ${path.basename(filePath)}',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 20),
              const Text(
                'To enable dynamic loading, add this to your page file:',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('// At the top of your page file:'),
                    Text('import \'package:vortex/vortex.dart\';'),
                    Text(''),
                    Text('class YourPage extends StatelessWidget {'),
                    Text('  // Your page implementation'),
                    Text('  // ...'),
                    Text('}'),
                    Text(''),
                    Text('// At the bottom of your file:'),
                    Text('// This enables automatic discovery'),
                    Text('@VortexPage(\'$routePath\')'),
                    Text(
                      'Widget createPage(BuildContext context) => YourPage();',
                    ),
                  ],
                ),
              ),
              if (routeArgs != null) ...[
                const SizedBox(height: 20),
                const Text(
                  'Route Parameters:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(
                  routeArgs.toString(),
                  style: const TextStyle(fontFamily: 'monospace'),
                ),
              ],
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (routePath != '/')
                    ElevatedButton(
                      onPressed:
                          () => Navigator.pushReplacementNamed(context, '/'),
                      child: const Text('Go Home'),
                    ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    } catch (e, stackTrace) {
      Log.e("Error loading page component from file $filePath: $e");
      Log.d("Stack trace: $stackTrace");
      return _ErrorPage(error: 'Error loading page: $e');
    }
  }

  /// Convert a file path to an import path
  static String _filePathToImportPath(String filePath) {
    try {
      // Extract the relative path from the project root
      final projectDir = _projectDirectory?.path ?? Directory.current.path;
      String relativePath = filePath;

      if (filePath.startsWith(projectDir)) {
        relativePath = filePath.substring(projectDir.length);
      }

      // Remove leading slash if present
      if (relativePath.startsWith('/')) {
        relativePath = relativePath.substring(1);
      }

      // Convert to package import format
      if (relativePath.startsWith('lib/')) {
        // For files in the lib directory, use package: import
        final packageName = _getPackageName();
        return 'package:$packageName/${relativePath.substring(4)}';
      } else {
        // For other files, use relative import
        return relativePath;
      }
    } catch (e) {
      Log.e("Error converting file path to import path: $e");
      return filePath;
    }
  }

  /// Get the package name from pubspec.yaml
  static String _getPackageName() {
    try {
      final projectDir = _projectDirectory?.path ?? Directory.current.path;
      final pubspecFile = File(path.join(projectDir, 'pubspec.yaml'));

      if (pubspecFile.existsSync()) {
        final content = pubspecFile.readAsStringSync();
        final nameMatch = RegExp(r'name:\s*([^\s]+)').firstMatch(content);
        if (nameMatch != null) {
          return nameMatch.group(1)!;
        }
      }
    } catch (e) {
      Log.e("Error getting package name: $e");
    }

    return 'app';
  }

  /// Try to create a widget from a type using reflection
  static Widget _createWidgetFromType(
    Type type,
    BuildContext context,
    dynamic args,
  ) {
    // This is a simplified implementation
    // In a real app, you would use a more robust reflection mechanism

    // For now, we'll just handle a few common cases
    if (type == StatelessWidget ||
        type.toString().contains('StatelessWidget')) {
      // Try to create a stateless widget
      try {
        // This is a placeholder - in a real implementation, you would use reflection
        return const Text('Dynamic widget creation not fully implemented');
      } catch (e) {
        Log.e("Error creating stateless widget: $e");
      }
    }

    // Default fallback
    return Text('Could not create widget of type: $type');
  }

  /// Try to load a component dynamically
  static Widget? _loadComponentDynamically(
    String filePath,
    String routePath,
    BuildContext context,
    dynamic args,
  ) {
    try {
      // For now, we'll try to use a convention-based approach
      final fileName = path.basename(filePath);
      final className = _fileNameToClassName(fileName);

      // Check for registered component via annotation
      final registeredComponent = VortexPageRegistry.getPageComponent(
        routePath,
      );
      if (registeredComponent != null) {
        return registeredComponent(context, args);
      }

      // Special handling for root path
      if (routePath == '/') {
        // Try with the index name
        final indexComponent = VortexPageRegistry.getPageComponent('index');
        if (indexComponent != null) {
          return indexComponent(context, args);
        }

        // Try with the home name
        final homeComponent = VortexPageRegistry.getPageComponent('home');
        if (homeComponent != null) {
          return homeComponent(context, args);
        }
      }

      // Handle dynamic routes with parameters
      if (routePath.contains(':')) {
        final paramComponent = VortexPageRegistry.findDynamicRouteComponent(
          routePath,
        );
        if (paramComponent != null) {
          return paramComponent(context, args);
        }
      }

      // If we get here, we couldn't find a matching component
      return _createDefaultNotFoundComponent(context, routePath, filePath);
    } catch (e) {
      Log.e("Error loading component dynamically: $e");
      return null;
    }
  }

  /// Create a default component for not found routes
  static Widget _createDefaultNotFoundComponent(
    BuildContext context,
    String routePath,
    String filePath,
  ) {
    return Scaffold(
      appBar: AppBar(title: Text('Route Not Found: $routePath')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 20),
            Text(
              'Route not found: $routePath',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              'File: ${path.basename(filePath)}',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 30),
            const Text(
              'To register this route, add the following to your page class:',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '@VortexPage(\'$routePath\')\nclass YourPageName extends StatelessWidget { ... }',
                style: const TextStyle(fontFamily: 'monospace'),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }

  /// Convert a file name to a class name
  static String _fileNameToClassName(String fileName) {
    // Remove .dart extension
    String baseName = fileName.replaceAll('.dart', '');

    // Handle special cases
    if (baseName == 'index') {
      baseName = 'Index';
    } else if (baseName.startsWith('[') && baseName.endsWith(']')) {
      // Dynamic route parameter
      baseName = baseName.substring(1, baseName.length - 1);
      baseName = 'Dynamic${baseName[0].toUpperCase()}${baseName.substring(1)}';
    }

    // Convert to PascalCase
    final words = baseName.split('_');
    return words
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join('');
  }

  /// Navigate to a route by path
  static Future<T?> navigateTo<T>(
    BuildContext context,
    String path, {
    Object? arguments,
  }) async {
    // Get the route configuration
    final routeBuilder = _routes[path];
    if (routeBuilder == null) {
      throw Exception('Route not found: $path');
    }
    // Check if there are any middleware for this route
    final middlewareList = VortexPageRegistry.getMiddlewareForRoute(path);

    // Execute middleware if available
    if (middlewareList.isNotEmpty) {
      final canProceed = await MiddlewareHandler.handle(
        context,
        path,
        middlewareList,
      );
      if (!canProceed) {
        // Middleware blocked navigation
        return null;
      }
    }

    // Proceed with navigation
    return Navigator.pushNamed<T>(context, path, arguments: arguments);
  }

  /// Navigate to a route and replace the current route
  static Future<T?> replaceTo<T>(
    BuildContext context,
    String path, {
    Object? arguments,
  }) async {
    // Check middleware before navigation
    final middlewareList = VortexPageRegistry.getMiddlewareForRoute(path);
    // Log.i('Middleware list: $middlewareList');
    if (middlewareList.isNotEmpty) {
      final canProceed = await MiddlewareHandler.handle(
        context,
        path,
        middlewareList,
      );
      if (!canProceed) {
        return null;
      }
    }

    return Navigator.pushReplacementNamed<T, dynamic>(
      context,
      path,
      arguments: arguments,
    );
  }

  /// Navigate to a route and remove all previous routes
  static Future<T?> navigateAndRemoveUntil<T>(
    BuildContext context,
    String path, {
    Object? arguments,
  }) async {
    // Check middleware before navigation
    final middlewareList = VortexPageRegistry.getMiddlewareForRoute(path);
    if (middlewareList.isNotEmpty) {
      final canProceed = await MiddlewareHandler.handle(
        context,
        path,
        middlewareList,
      );
      if (!canProceed) {
        return null;
      }
    }

    return Navigator.pushNamedAndRemoveUntil<T>(
      context,
      path,
      (route) => false,
      arguments: arguments,
    );
  }

  /// Register a layout for a route
  static void registerLayout(String routePath, Widget Function(Widget) layout) {
    _layouts[routePath] = layout;
  }

  /// Get layout for a route
  static Widget Function(Widget)? getLayout(String routePath) {
    // Try exact match first
    if (_layouts.containsKey(routePath)) {
      return _layouts[routePath];
    }

    // Try to find parent layout
    final segments = routePath.split('/');
    while (segments.isNotEmpty) {
      segments.removeLast();
      final parentPath = segments.join('/');
      if (_layouts.containsKey(parentPath)) {
        return _layouts[parentPath];
      }
    }

    return null;
  }

  /// Build a page with layout and middleware handling
  static Widget buildPage(
    BuildContext context,
    String path, {
    Object? arguments,
  }) {
    final middlewareList = VortexPageRegistry.getMiddlewareForRoute(path);
    final routeBuilder = _routes[path];
    final layout = getLayout(path);

    if (routeBuilder == null) {
      return _NotFoundPage(routeName: path);
    }

    Widget page = routeBuilder(context);

    // Apply layout if exists
    if (layout != null) {
      page = layout(page);
    }

    // Handle middleware
    if (middlewareList.isNotEmpty) {
      return FutureBuilder<bool>(
        future: MiddlewareHandler.handle(context, path, middlewareList),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (snapshot.data == true) {
            return page;
          }

          return const Scaffold(body: SizedBox.shrink());
        },
      );
    }

    return page;
  }

  /// Get all routes for use with MaterialApp
  // static Map<String, WidgetBuilder> get routes => _routes;

  /// Get the initial route handler for MaterialApp
  static Route<dynamic> Function(RouteSettings) get initialRouteHandler {
    return (RouteSettings settings) {
      final routeName = settings.name ?? '/';
      final routeBuilder = _routes[routeName];

      if (routeBuilder != null) {
        // Check for middleware
        final middlewareList = VortexPageRegistry.getMiddlewareForRoute(
          routeName,
        );

        if (middlewareList.isNotEmpty) {
          // For initial route, we need to handle middleware differently
          return MaterialPageRoute(
            builder: (context) {
              return FutureBuilder<bool>(
                future: MiddlewareHandler.handle(
                  context,
                  routeName,
                  middlewareList,
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Scaffold(
                      body: Center(child: CircularProgressIndicator()),
                    );
                  }

                  if (snapshot.data == true) {
                    // Middleware allowed access
                    return routeBuilder(context);
                  } else {
                    // Middleware blocked access, redirect to login
                    final loginRouteBuilder = _routes['/login'];
                    if (loginRouteBuilder != null) {
                      // We can safely navigate now because Navigator is initialized
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        Navigator.of(context).pushReplacementNamed('/login');
                      });
                      return const Scaffold(
                        body: Center(child: CircularProgressIndicator()),
                      );
                    } else {
                      return const Scaffold(
                        body: Center(
                          child: Text(
                            'Authentication required. Login page not found.',
                          ),
                        ),
                      );
                    }
                  }
                },
              );
            },
            settings: settings,
          );
        } else {
          // No middleware, just return the route
          return MaterialPageRoute(builder: routeBuilder, settings: settings);
        }
      }

      // Route not found
      return MaterialPageRoute(
        builder: (context) => _NotFoundPage(routeName: routeName),
        settings: settings,
      );
    };
  }

  /// Route generator for dynamic routes
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    final routeName = settings.name ?? '/';
    // First check if it's a registered route
    if (_routes.containsKey(routeName)) {
      return MaterialPageRoute(
        builder: _routes[routeName]!,
        settings: settings,
      );
    }

    // Special case for root route
    if (routeName == '/' && _routes.isNotEmpty) {
      final firstRoute = _routes.entries.first;
      return MaterialPageRoute(
        builder: firstRoute.value,
        settings: const RouteSettings(name: '/'),
      );
    }

    // Handle dynamic routes
    final uri = Uri.parse(routeName);
    final pathSegments = uri.pathSegments;

    // Try to match dynamic routes like /todos/:id
    String? matchedRoute;
    Map<String, String> params = {};

    for (final route in _routes.keys) {
      final routeSegments = Uri.parse(route).pathSegments;

      if (routeSegments.length == pathSegments.length) {
        bool isMatch = true;
        for (int i = 0; i < routeSegments.length; i++) {
          final routeSeg = routeSegments[i];
          final pathSeg = pathSegments[i];

          if (routeSeg.startsWith(':')) {
            // This is a parameter segment
            final paramName = routeSeg.substring(1);
            params[paramName] = pathSeg;
          } else if (routeSeg != pathSeg) {
            isMatch = false;
            break;
          }
        }

        if (isMatch) {
          matchedRoute = route;
          break;
        }
      }
    }

    if (matchedRoute != null) {
      return MaterialPageRoute(
        builder: (context) {
          final builder = _routes[matchedRoute]!;
          return builder(context);
        },
        settings: RouteSettings(
          name: settings.name,
          arguments: {
            ...params,
            if (settings.arguments is Map)
              ...(settings.arguments as Map).cast<String, dynamic>(),
          },
        ),
      );
    }

    // Return a 404 page if no route matches
    Log.w("No route match found for: $routeName");
    return MaterialPageRoute(
      builder: (context) => _NotFoundPage(routeName: routeName),
      settings: settings,
    );
  }

  /// Reset the router state (for testing)
  static void reset() {
    _routes.clear();
    _routesDiscovered = false;
  }
}

/// Default home page shown when no home route is defined
class _DefaultHomePage extends StatelessWidget {
  const _DefaultHomePage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vortex')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Welcome to Vortex!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            const Text(
              'Create a pages directory to get started with file-based routing.',
            ),
            const SizedBox(height: 40),
            const Text(
              'Example structure:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('lib/pages/'),
                  Text(
                    '  index.dart         -> /',
                    style: TextStyle(color: Colors.blue),
                  ),
                  Text(
                    '  about.dart         -> /about',
                    style: TextStyle(color: Colors.blue),
                  ),
                  Text('  todos/'),
                  Text(
                    '    index.dart       -> /todos',
                    style: TextStyle(color: Colors.blue),
                  ),
                  Text(
                    '    [id].dart        -> /todos/:id',
                    style: TextStyle(color: Colors.blue),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 404 page shown when no route matches
class _NotFoundPage extends StatelessWidget {
  final String routeName;

  const _NotFoundPage({required this.routeName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Page Not Found')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '404',
              style: TextStyle(
                fontSize: 72,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 20),
            const Text('Page Not Found', style: TextStyle(fontSize: 24)),
            const SizedBox(height: 10),
            Text(
              'No route defined for: $routeName',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () => Navigator.pushReplacementNamed(context, '/'),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Error page shown when an error occurs while loading a page
class _ErrorPage extends StatelessWidget {
  final String error;

  const _ErrorPage({required this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Error')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 20),
            const Text('Error Loading Page', style: TextStyle(fontSize: 24)),
            const SizedBox(height: 10),
            Text(error, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Base class for layout components
abstract class VortexLayout extends StatelessWidget {
  final Widget child;

  const VortexLayout({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return buildLayout(context, child);
  }

  /// Build the layout with the child widget
  Widget buildLayout(BuildContext context, Widget child);
}

/// Default layout that can be extended
class DefaultLayout extends VortexLayout {
  const DefaultLayout({Key? key, required Widget child})
    : super(key: key, child: child);

  @override
  Widget buildLayout(BuildContext context, Widget child) {
    return Scaffold(appBar: AppBar(title: const Text('Vortex')), body: child);
  }
}

/// Router class that handles navigation and route management
class Router {
  static final Router _instance = Router._internal();
  factory Router() => _instance;
  Router._internal();

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  final Map<String, WidgetBuilder> _routes = {};
  final Map<String, List<VortexMiddleware>> _middlewareMap = {};
  final _routeStreamController = StreamController<String>.broadcast();
  String _currentRoute = '/';

  /// Stream of route changes
  Stream<String> get routeStream => _routeStreamController.stream;

  /// Current route
  String get currentRoute => _currentRoute;

  /// Initialize router with routes and middleware
  Future<void> initialize() async {
    await _discoverRoutes();
    await _registerMiddleware();
  }

  /// Discover routes from the file system
  Future<void> _discoverRoutes() async {
    // Implementation for route discovery
    Log.i('Discovering routes...');
  }

  /// Register middleware for routes
  Future<void> _registerMiddleware() async {
    // Implementation for middleware registration
    Log.i('Registering middleware...');
  }

  /// Navigate to a route
  Future<T?> navigateTo<T>(String route, {Object? arguments}) async {
    if (!_routes.containsKey(route)) {
      Log.e('Route not found: $route');
      return null;
    }

    final middlewares = _middlewareMap[route] ?? [];
    for (final middleware in middlewares) {
      final result = await middleware.execute(
        navigatorKey.currentContext!,
        route,
      );
      if (!result) {
        Log.w('Navigation blocked by middleware: ${middleware.runtimeType}');
        return null;
      }
    }

    _currentRoute = route;
    _routeStreamController.add(route);

    return navigatorKey.currentState?.pushNamed<T>(route, arguments: arguments);
  }

  /// Replace current route
  Future<T?> replaceRoute<T>(String route, {Object? arguments}) async {
    if (!_routes.containsKey(route)) {
      Log.e('Route not found: $route');
      return null;
    }

    final middlewares = _middlewareMap[route] ?? [];
    for (final middleware in middlewares) {
      final result = await middleware.execute(
        navigatorKey.currentContext!,
        route,
      );
      if (!result) {
        Log.w('Navigation blocked by middleware: ${middleware.runtimeType}');
        return null;
      }
    }

    _currentRoute = route;
    _routeStreamController.add(route);

    final result = await navigatorKey.currentState?.pushReplacementNamed<T, T>(
      route,
      arguments: arguments,
    );
    return result;
  }

  /// Pop current route
  void pop<T>([T? result]) {
    navigatorKey.currentState?.pop<T>(result);
  }

  /// Pop until route
  void popUntil(String route) {
    navigatorKey.currentState?.popUntil(ModalRoute.withName(route));
  }

  /// Clear all routes and navigate to home
  void clearAndNavigateToHome() {
    navigatorKey.currentState?.pushNamedAndRemoveUntil('/', (route) => false);
  }

  /// Add a route with middleware
  void addRoute(
    String route,
    WidgetBuilder builder, {
    List<VortexMiddleware>? middleware,
  }) {
    _routes[route] = builder;
    if (middleware != null) {
      _middlewareMap[route] = middleware;
    }
  }

  /// Remove a route
  void removeRoute(String route) {
    _routes.remove(route);
    _middlewareMap.remove(route);
  }

  /// Get route builder
  WidgetBuilder? getRouteBuilder(String route) => _routes[route];

  /// Get middleware for route
  List<VortexMiddleware> getMiddlewareForRoute(String route) =>
      _middlewareMap[route] ?? [];

  /// Dispose router
  void dispose() {
    _routeStreamController.close();
  }
}

/// Router widget that provides navigation context
class RouterWidget extends StatelessWidget {
  final Widget child;

  const RouterWidget({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: Router().navigatorKey,
      onGenerateRoute: (settings) {
        final builder = Router().getRouteBuilder(settings.name ?? '/');
        if (builder == null) {
          return MaterialPageRoute(
            builder:
                (context) => const Scaffold(
                  body: Center(child: Text('Route not found')),
                ),
          );
        }
        return MaterialPageRoute(builder: builder, settings: settings);
      },
      home: child,
    );
  }
}
