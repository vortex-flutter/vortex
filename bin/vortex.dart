import 'dart:io';
import 'package:args/args.dart';
import 'package:logger/logger.dart';
import 'package:path/path.dart' as path;

final Logger logger = Logger(printer: PrettyPrinter());

// Add a new command for scanning components
void main(List<String> arguments) {
  final parser =
      ArgParser()
        ..addCommand(
          'runner',
          ArgParser()
            ..addOption(
              'pages-dir',
              abbr: 'p',
              help: 'Directory containing page components',
              defaultsTo: 'lib/pages',
            )
            ..addFlag(
              'verbose',
              abbr: 'v',
              help: 'Enable verbose logging',
              defaultsTo: false,
            ),
        )
        ..addCommand(
          'components',
          ArgParser()
            ..addOption(
              'components-dir',
              abbr: 'c',
              help: 'Directory containing components',
              defaultsTo: 'lib/components',
            )
            ..addFlag(
              'verbose',
              abbr: 'v',
              help: 'Enable verbose logging',
              defaultsTo: false,
            ),
        )
        ..addCommand(
          'page',
          ArgParser()
            ..addOption(
              'name',
              abbr: 'n',
              help: 'Name of the page to generate',
              mandatory: true,
            )
            ..addOption(
              'type',
              abbr: 't',
              help: 'Type of widget (stateless or stateful)',
              allowed: ['stateless', 'stateful'],
              defaultsTo: 'stateless',
            )
            ..addOption('route', abbr: 'r', help: 'Route path for the page')
            ..addOption(
              'dir',
              abbr: 'd',
              help: 'Directory to create the page in',
              defaultsTo: 'lib/pages',
            )
            ..addOption(
              'file',
              abbr: 'f',
              help: 'Custom file name (e.g., index.dart)',
            ),
        )
        ..addCommand(
          'create',
          ArgParser()
            ..addOption(
              'name',
              abbr: 'n',
              help: 'Name of the app to create',
              defaultsTo: 'vortex_app',
            )
            ..addOption(
              'org',
              abbr: 'o',
              help: 'Organization name (e.g., com.example)',
              defaultsTo: 'com.example',
            )
            ..addFlag(
              'verbose',
              abbr: 'v',
              help: 'Enable verbose logging',
              defaultsTo: false,
            ),
        )
        ..addFlag(
          'help',
          abbr: 'h',
          negatable: false,
          help: 'Displays this help information.',
        );

  final argResults = parser.parse(arguments);

  if (argResults['help'] as bool) {
    _printUsage(parser);
    return;
  }

  if (argResults.command?.name == 'runner') {
    _runRouterScanner(argResults.command!);
  } else if (argResults.command?.name == 'components') {
    _runComponentScanner(argResults.command!);
  } else if (argResults.command?.name == 'page') {
    _generatePage(argResults.command!);
  } else if (argResults.command?.name == 'create') {
    _createApp(argResults.command!);
  } else {
    logger.i('Invalid command.');
    _printUsage(parser);
  }
}

/// Run the router scanner to find and register pages
void _runRouterScanner(ArgResults args) {
  final pagesDir = args['pages-dir'] as String;
  final verbose = args['verbose'] as bool;

  logger.i("Running FlutterWind router scanner...");
  logger.i("Scanning for pages in: $pagesDir");

  final projectDir = Directory.current.path;
  final fullPagesDir = path.join(projectDir, pagesDir);

  // Check if the pages directory exists
  if (!Directory(fullPagesDir).existsSync()) {
    logger.e("Pages directory not found: $fullPagesDir");
    return;
  }

  try {
    // Scan for page files
    final pageFiles = _findPageFiles(fullPagesDir);
    logger.i("Found ${pageFiles.length} page files");

    if (verbose) {
      for (final file in pageFiles) {
        logger.d("Page file: ${path.relative(file.path, from: projectDir)}");
      }
    }

    // Generate the route registration code
    _generateRouteRegistration(projectDir, pageFiles);

    logger.i("FlutterWind router scanner completed successfully");
  } catch (e, stackTrace) {
    logger.e("Error running router scanner", error: e, stackTrace: stackTrace);
  }
}

/// Find all page files in the given directory
List<File> _findPageFiles(String directory) {
  return Directory(directory)
      .listSync(recursive: true)
      .where(
        (entity) =>
            entity is File &&
            entity.path.endsWith('.dart') &&
            _containsPageAnnotation(entity),
      )
      .cast<File>()
      .toList();
}

/// Check if a file contains the FlutterWindPage annotation
bool _containsPageAnnotation(File file) {
  try {
    final content = file.readAsStringSync();
    return content.contains('@FlutterWindPage');
  } catch (e) {
    logger.e("Error reading file: ${file.path}", error: e);
    return false;
  }
}

/// Generate route registration code
void _generateRouteRegistration(String projectDir, List<File> pageFiles) {
  try {
    final outputDir = path.join(projectDir, 'lib', 'generated');
    final outputFile = File(path.join(outputDir, 'routes.dart'));

    // Create the output directory if it doesn't exist
    if (!Directory(outputDir).existsSync()) {
      Directory(outputDir).createSync(recursive: true);
    }

    // Generate the route registration code
    final buffer = StringBuffer();
    buffer.writeln('// GENERATED CODE - DO NOT MODIFY BY HAND');
    buffer.writeln('// Generated by FlutterWind Runner');
    buffer.writeln('// ');
    buffer.writeln('// To regenerate this file, run:');
    buffer.writeln('// flutter pub run flutterwind_core runner');
    buffer.writeln('');
    buffer.writeln('import \'package:flutterwind_core/flutterwind.dart\';');
    buffer.writeln('');

    // Track imported files to avoid duplicates
    final importedFiles = <String>{};

    // Import all page files
    for (final file in pageFiles) {
      final relativePath = path.relative(file.path, from: projectDir);
      final importPath = relativePath
          .replaceAll('\\', '/')
          .replaceFirst(RegExp(r'^lib/'), '');

      final importStatement =
          'import \'package:${_getPackageName(projectDir)}/$importPath\';';

      // Only add the import if we haven't seen it before
      if (importedFiles.add(importPath)) {
        buffer.writeln(importStatement);
      }
    }

    buffer.writeln('');
    buffer.writeln('/// Initialize all routes');
    buffer.writeln('void initializeFlutterWindRoutes() {');

    // Add route registration calls
    for (final file in pageFiles) {
      final content = file.readAsStringSync();
      final annotationMatch = RegExp(
        r'''@FlutterWindPage\(\s*(['"])(.*?)\1\s*(?:,\s*middleware\s*:\s*\[(.*?)\])?\s*\)''',
      ).firstMatch(content);

      if (annotationMatch != null) {
        var routePath = annotationMatch.group(2)!;
        final middlewareStr = annotationMatch.group(3);

        // Normalize empty paths to root path '/'
        if (routePath.isEmpty) {
          routePath = '/';
        }

        // Parse middleware list if present
        List<String> middleware = [];
        if (middlewareStr != null && middlewareStr.isNotEmpty) {
          middleware =
              middlewareStr
                  .split(',')
                  .map(
                    (m) => m.trim().replaceAll(RegExp(r'''^['"]|['"]$'''), ''),
                  )
                  .where((m) => m.isNotEmpty)
                  .toList();
        }

        final classMatch = RegExp(
          r'class\s+(\w+)\s+extends\s+(StatelessWidget|StatefulWidget)',
        ).firstMatch(content);

        if (classMatch != null) {
          final className = classMatch.group(1)!;
          if (middleware.isNotEmpty) {
            buffer.writeln('  // Register route for $className');
            buffer.writeln('  FlutterWindPageRegistry.registerPage(');
            buffer.writeln('    \'$routePath\',');
            buffer.writeln('    (context, args) => const $className(),');
            buffer.writeln(
              '    middleware: [${middleware.map((m) => '\'$m\'').join(', ')}],',
            );
            buffer.writeln('  );');
          } else {
            buffer.writeln('  // Register route for $className');
            buffer.writeln(
              '  FlutterWindPageRegistry.registerPage(\'$routePath\', (context, args) => const $className());',
            );
          }
        }
      }
    }

    buffer.writeln('}');

    // Write the generated code to the output file
    outputFile.writeAsStringSync(buffer.toString());

    logger.i("Generated route registration code: ${outputFile.path}");
    logger.i("Add the following to your main.dart file:");
    logger.i(
      "import 'package:${_getPackageName(projectDir)}/generated/routes.dart';",
    );
    logger.i("void main() {");
    logger.i("  initializeFlutterWindRoutes();");
    logger.i("  runApp(const MyApp());");
    logger.i("}");
  } catch (e, stackTrace) {
    logger.e(
      "Error generating route registration code",
      error: e,
      stackTrace: stackTrace,
    );
  }
}

/// Get the package name from pubspec.yaml
String _getPackageName(String projectDir) {
  try {
    final pubspecFile = File(path.join(projectDir, 'pubspec.yaml'));

    if (pubspecFile.existsSync()) {
      final content = pubspecFile.readAsStringSync();
      final nameMatch = RegExp(r'name:\s*([^\s]+)').firstMatch(content);
      if (nameMatch != null) {
        return nameMatch.group(1)!;
      }
    }
  } catch (e) {
    logger.e("Error getting package name", error: e);
  }

  return 'app';
}

/// Generate a new page
void _generatePage(ArgResults args) {
  final pageName = args['name'] as String;
  final pageType = args['type'] as String;
  final pageDir = args['dir'] as String;
  final routePath = args['route'] as String? ?? '/${pageName.toLowerCase()}';
  final customFileName = args['file'] as String?;

  logger.i("Generating $pageType page: $pageName");
  logger.i("Route path: $routePath");

  try {
    // Create the directory if it doesn't exist
    final projectDir = Directory.current.path;
    final fullPageDir = path.join(projectDir, pageDir);

    if (!Directory(fullPageDir).existsSync()) {
      Directory(fullPageDir).createSync(recursive: true);
      logger.i("Created directory: $pageDir");
    }

    // Determine the file path
    // Determine the file path
    final fileName =
        customFileName != null
            ? customFileName.endsWith('.dart')
                ? customFileName
                : '$customFileName.dart'
            : '${_getFileNameFromPageName(pageName)}.dart';
    final filePath = path.join(fullPageDir, fileName);

    // Check if the file already exists
    if (File(filePath).existsSync()) {
      logger.e("File already exists: $filePath");
      return;
    }

    // Generate the page content
    final pageContent = _generatePageContent(pageName, pageType, routePath);

    // Write the file
    File(filePath).writeAsStringSync(pageContent);

    logger.i("Generated page at: $filePath");
    logger.i("To use this page, run: flutter pub run flutterwind runner");

    // Automatically run the router scanner
    logger.i("Running router scanner to update routes...");
    final runnerArgs =
        ArgParser()
          ..addOption('pages-dir', defaultsTo: 'lib/pages')
          ..addFlag('verbose', defaultsTo: false);

    final parsedRunnerArgs = runnerArgs.parse([]);
    _runRouterScanner(parsedRunnerArgs);
  } catch (e, stackTrace) {
    logger.e("Error generating page", error: e, stackTrace: stackTrace);
  }
}

/// Generate the content for a new page
String _generatePageContent(
  String pageName,
  String pageType,
  String routePath,
) {
  final className = _getClassNameFromPageName(pageName);

  if (pageType == 'stateless') {
    return '''
import 'package:flutter/material.dart';
import 'package:flutterwind_core/flutterwind.dart';

/// $className page
@FlutterWindPage('$routePath')
class $className extends StatelessWidget {
  const $className({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
''';
  } else {
    return '''
import 'package:flutter/material.dart';
import 'package:flutterwind_core/flutterwind.dart';

/// $className page
@FlutterWindPage('$routePath')
class $className extends StatefulWidget {
  const $className({Key? key}) : super(key: key);

  @override
  State<$className> createState() => _${className}State();
}

class _${className}State extends State<$className> {
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
''';
  }
}

/// Convert a page name to a file name
String _getFileNameFromPageName(String pageName) {
  // Convert PascalCase or camelCase to snake_case
  final fileName =
      pageName
          .replaceAllMapped(
            RegExp(r'[A-Z]'),
            (match) => '_${match.group(0)!.toLowerCase()}',
          )
          .toLowerCase();

  // Remove leading underscore if present
  return fileName.startsWith('_') ? fileName.substring(1) : fileName;
}

/// Convert a page name to a class name
String _getClassNameFromPageName(String pageName) {
  // Ensure the class name starts with an uppercase letter
  if (pageName.isEmpty) return 'Page';

  // If it's already PascalCase, return as is
  if (pageName[0] == pageName[0].toUpperCase()) {
    return pageName;
  }

  // Convert first letter to uppercase
  return pageName[0].toUpperCase() + pageName.substring(1);
}

void _printUsage(ArgParser parser) {
  logger.i('Usage: flutter pub run flutterwind [command]');
  logger.i('Commands:');
  logger.i('  runner   Scan and register page components');
  logger.i('  page     Generate a new page component');
  logger.i('    --name, -n (required)  Name of the page to generate');
  logger.i('    --type, -t             Type of widget (stateless or stateful)');
  logger.i('    --route, -r            Route path for the page');
  logger.i('    --dir, -d              Directory to create the page in');
  logger.i('    --file, -f             Custom file name (e.g., index.dart)');
  logger.i('  components Scan and register components');
  logger.i('  create     Create a new Vortex app with proper structure');
  logger.i('    --name, -n             Name of the app to create');
  logger.i('    --org, -o              Organization name (e.g., com.example)');
  logger.i(parser.usage);
}

void _createApp(ArgResults args) {
  final appName = args['name'] as String;
  final orgName = args['org'] as String;
  final verbose = args['verbose'] as bool;

  logger.i("Creating new Vortex app: $appName");
  logger.i("Organization: $orgName");

  try {
    final result = Process.runSync('flutter', [
      'create',
      '--org=$orgName',
      '--project-name=$appName',
      appName,
    ]);

    if (result.exitCode != 0) {
      logger.e("Error creating Flutter app: ${result.stderr}");
      return;
    }

    logger.i("Flutter app created successfully");

    // Change to the app directory
    final appDir = Directory(path.join(Directory.current.path, appName));

    if (verbose) {
      logger.d("Changing to directory: ${appDir.path}");
    }

    // Create Nuxt-like folder structure
    _createNuxtLikeFolderStructure(appDir.path, verbose);

    // Update pubspec.yaml to add flutterwind_core dependency
    _updatePubspecYaml(appDir.path);

    // Create main.dart with Vortex initialization
    _createMainDart(appDir.path);

    // Create example pages
    _createExamplePages(appDir.path);

    // Run flutter pub get
    final pubGetResult = Process.runSync('flutter', [
      'pub',
      'get',
    ], workingDirectory: appDir.path);

    if (pubGetResult.exitCode != 0) {
      logger.e("Error running flutter pub get: ${pubGetResult.stderr}");
    } else {
      logger.i("Dependencies installed successfully");
    }

    // Run the router scanner
    final runnerResult = Process.runSync('flutter', [
      'pub',
      'run',
      'vortex',
      'runner',
    ], workingDirectory: appDir.path);

    if (runnerResult.exitCode != 0) {
      logger.e("Error running router scanner: ${runnerResult.stderr}");
    } else {
      logger.i("Router scanner completed successfully");
    }

    // Run the component scanner
    final componentResult = Process.runSync('flutter', [
      'pub',
      'run',
      'vortex',
      'components',
    ], workingDirectory: appDir.path);

    if (componentResult.exitCode != 0) {
      logger.e("Error running component scanner: ${componentResult.stderr}");
    } else {
      logger.i("Component scanner completed successfully");
    }

    logger.i("Vortex app created successfully at: ${appDir.path}");
    logger.i("To run your app:");
    logger.i("  cd $appName");
    logger.i("  flutter run vortex");
  } catch (e, stackTrace) {
    logger.e("Error creating Vortex app", error: e, stackTrace: stackTrace);
  }
}

/// Create Nuxt-like folder structure
void _createNuxtLikeFolderStructure(String appDir, bool verbose) {
  final directories = [
    'lib/pages',
    'lib/components',
    'lib/layouts',
    'lib/middleware',
    'lib/plugins',
    'lib/store',
    'lib/assets',
  ];

  for (final dir in directories) {
    final directory = Directory(path.join(appDir, dir));
    directory.createSync(recursive: true);

    if (verbose) {
      logger.d("Created directory: $dir");
    }
  }

  logger.i("Created folder structure");
}

/// Update pubspec.yaml to add flutterwind_core dependency
void _updatePubspecYaml(String appDir) {
  final pubspecFile = File(path.join(appDir, 'pubspec.yaml'));
  var content = pubspecFile.readAsStringSync();

  // Add flutterwind_core dependency
  final dependenciesMatch = RegExp(
    r'dependencies:[\s\S]*?dev_dependencies:',
  ).firstMatch(content);

  if (dependenciesMatch != null) {
    final dependenciesSection = dependenciesMatch.group(0)!;
    final updatedDependenciesSection = dependenciesSection.replaceFirst(
      'dependencies:',
      'dependencies:\n  flutterwind_core: 0.0.3\n  vortex: ^0.0.1',
    );

    content = content.replaceFirst(
      dependenciesSection,
      updatedDependenciesSection,
    );
    pubspecFile.writeAsStringSync(content);

    logger.i("Added flutterwind_core: 0.0.3 to pubspec.yaml");
  } else {
    logger.e("Could not find dependencies section in pubspec.yaml");
  }
}

/// Create main.dart with Vortex initialization
void _createMainDart(String appDir) {
  final mainFile = File(path.join(appDir, 'lib', 'main.dart'));

  final content = '''
import 'package:flutter/material.dart';
import 'package:vortex/vortex.dart';
import 'package:${path.basename(appDir)}/generated/routes.dart';
import 'package:${path.basename(appDir)}/generated/components.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Vortex
  await Vortex.initialize();
  
  // Initialize routes and components
  initializeFlutterWindRoutes();
  initializeFlutterWindComponents();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Vortex(
      child: FlutterWind(
        child: MaterialApp(
          title: '${path.basename(appDir)}',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
            useMaterial3: true,
            brightness: Brightness.light,
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.deepPurple,
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
            brightness: Brightness.dark,
          ),
          themeMode: ThemeMode.light,
          initialRoute: '/',
          onGenerateInitialRoutes:
              (initialRoute) => [
                VortexRouter.initialRouteHandler(
                  RouteSettings(name: initialRoute),
                ),
              ],
          onGenerateRoute: VortexRouter.onGenerateRoute,
        ),
      ),
    );
  }
}
''';

  mainFile.writeAsStringSync(content);
  logger.i("Created main.dart with Vortex initialization");
}

/// Create example pages
void _createExamplePages(String appDir) {
  final homePageFile = File(path.join(appDir, 'lib', 'pages', 'index.dart'));

  final homePageContent = '''
import 'package:flutter/material.dart';
import 'package:flutterwind_core/flutterwind.dart';

/// Home page
@FlutterWindPage('/')
class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Welcome to Vortex!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/about');
              },
              child: const Text('Go to About'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/counter');
              },
              child: const Text('Go to Counter'),
            ),
          ],
        ),
      ),
    );
  }
}
''';
  homePageFile.writeAsStringSync(homePageContent);

  logger.i("Created example pages");
}

/// Run the component scanner to find and register components
void _runComponentScanner(ArgResults args) {
  final componentsDir = args['components-dir'] as String;
  final verbose = args['verbose'] as bool;

  logger.i("Running FlutterWind component scanner...");
  logger.i("Scanning for components in: $componentsDir");

  final projectDir = Directory.current.path;
  final fullComponentsDir = path.join(projectDir, componentsDir);

  // Check if the components directory exists
  if (!Directory(fullComponentsDir).existsSync()) {
    logger.e("Components directory not found: $fullComponentsDir");
    return;
  }

  try {
    // Scan for component files
    final componentFiles = _findComponentFiles(fullComponentsDir);
    logger.i("Found ${componentFiles.length} component files");

    if (verbose) {
      for (final file in componentFiles) {
        logger.d(
          "Component file: ${path.relative(file.path, from: projectDir)}",
        );
      }
    }

    // Generate the component registration code
    _generateComponentRegistration(projectDir, componentFiles);

    logger.i("FlutterWind component scanner completed successfully");
  } catch (e, stackTrace) {
    logger.e(
      "Error running component scanner",
      error: e,
      stackTrace: stackTrace,
    );
  }
}

/// Find all component files in the given directory
List<File> _findComponentFiles(String directory) {
  return Directory(directory)
      .listSync(recursive: true)
      .where(
        (entity) =>
            entity is File &&
            entity.path.endsWith('.dart') &&
            _containsComponentAnnotation(entity),
      )
      .cast<File>()
      .toList();
}

/// Check if a file contains the Component annotation
bool _containsComponentAnnotation(File file) {
  try {
    final content = file.readAsStringSync();
    return content.contains('@Component');
  } catch (e) {
    logger.e("Error reading file: ${file.path}", error: e);
    return false;
  }
}

/// Generate component registration code
void _generateComponentRegistration(
  String projectDir,
  List<File> componentFiles,
) {
  try {
    final outputDir = path.join(projectDir, 'lib', 'generated');
    final outputFile = File(path.join(outputDir, 'components.dart'));

    // Create the output directory if it doesn't exist
    if (!Directory(outputDir).existsSync()) {
      Directory(outputDir).createSync(recursive: true);
    }

    // Generate the component registration code
    final buffer = StringBuffer();
    buffer.writeln('// GENERATED CODE - DO NOT MODIFY BY HAND');
    buffer.writeln('// Generated by FlutterWind Component Scanner');
    buffer.writeln('// ');
    buffer.writeln('// To regenerate this file, run:');
    buffer.writeln('// flutter pub run flutterwind_core components');
    buffer.writeln('');
    buffer.writeln('import \'package:flutter/widgets.dart\';');
    buffer.writeln('import \'package:flutterwind_core/flutterwind.dart\';');
    buffer.writeln('');

    // Track imported files to avoid duplicates
    final importedFiles = <String>{};

    // Import all component files
    for (final file in componentFiles) {
      final relativePath = path.relative(file.path, from: projectDir);
      final importPath = relativePath
          .replaceAll('\\', '/')
          .replaceFirst(RegExp(r'^lib/'), '');

      final importStatement =
          'import \'package:${_getPackageName(projectDir)}/$importPath\';';

      // Only add the import if we haven't seen it before
      if (importedFiles.add(importPath)) {
        buffer.writeln(importStatement);
      }
    }

    // Add additional imports that might be needed for component parameters
    buffer.writeln('import \'dart:ui\';');
    buffer.writeln('import \'package:flutter/material.dart\';');

    buffer.writeln('');
    buffer.writeln('/// Initialize all components');
    buffer.writeln('void initializeFlutterWindComponents() {');

    // Add component registration calls
    for (final file in componentFiles) {
      final content = file.readAsStringSync();

      // Extract class name
      final classMatch = RegExp(
        r'class\s+(\w+)\s+extends\s+StatelessWidget',
      ).firstMatch(content);

      if (classMatch != null) {
        final className = classMatch.group(1)!;
        buffer.writeln('  // Register component $className');
        buffer.writeln(
          '  ComponentRegistry.register(\'$className\', (props) {',
        );
        buffer.writeln('    // Convert props to the appropriate parameters');
        buffer.writeln('    return $className(');
        buffer.writeln('      key: props[\'key\'] as Key?,');

        // Extract constructor parameters by analyzing class fields
        final fieldRegex = RegExp(
          r'final\s+(\w+(?:<[^>]+>)?)\s+(\w+);',
          multiLine: true,
        );
        final fieldMatches = fieldRegex.allMatches(content);

        for (final match in fieldMatches) {
          final fieldType = match.group(1)!;
          final fieldName = match.group(2)!;

          if (fieldName != 'key') {
            // Skip the key field as it's already handled
            // Check if the field is required
            final isRequired = content.contains('required this.$fieldName');

            if (isRequired) {
              buffer.writeln(
                '      $fieldName: props[\'$fieldName\'] as $fieldType,',
              );
            } else {
              buffer.writeln(
                '      $fieldName: props[\'$fieldName\'] as $fieldType?,',
              );
            }
          }
        }

        buffer.writeln('    );');
        buffer.writeln('  });');
      }
    }

    buffer.writeln('}');

    // Write the generated code to the output file
    outputFile.writeAsStringSync(buffer.toString());

    logger.i("Generated component registration code: ${outputFile.path}");
    logger.i("Add the following to your main.dart file:");
    logger.i(
      "import 'package:${_getPackageName(projectDir)}/generated/components.dart';",
    );
    logger.i("void main() {");
    logger.i("  initializeFlutterWindComponents();");
    logger.i("  runApp(const MyApp());");
    logger.i("}");
  } catch (e, stackTrace) {
    logger.e(
      "Error generating component registration code",
      error: e,
      stackTrace: stackTrace,
    );
  }
}
