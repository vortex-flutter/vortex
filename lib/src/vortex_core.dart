import 'dart:io';

import 'package:flutter/material.dart';
import '../vortex.dart';
import 'package:vortex/src/components/error_boundary.dart';
import 'package:vortex/src/reactive/store.dart';
import 'package:yaml/yaml.dart';

/// Configuration class for Vortex
class VortexConfig {
  final bool storeEnabled;
  final bool storePersistent;
  final bool storeLog;
  final bool useFlutterWind;
  final String outputDir;

  VortexConfig({
    required this.storeEnabled,
    required this.storePersistent,
    required this.storeLog,
    required this.useFlutterWind,
    required this.outputDir,
  });

  factory VortexConfig.fromYaml(YamlMap yaml) {
    return VortexConfig(
      storeEnabled: yaml['store']?['enabled'] ?? false,
      storePersistent: yaml['store']?['persistent'] ?? false,
      storeLog: yaml['store']?['log'] ?? false,
      useFlutterWind: yaml['compiler']?['useFlutterWind'] ?? false,
      outputDir: yaml['compiler']?['outputDir'] ?? 'dist',
    );
  }

  factory VortexConfig.defaultConfig() {
    return VortexConfig(
      storeEnabled: false,
      storePersistent: false,
      storeLog: false,
      useFlutterWind: false,
      outputDir: 'dist',
    );
  }
}

/// Main Vortex widget that provides the framework context
class Vortex extends StatefulWidget {
  final Widget child;
  final String? configPath;
  static bool _isInitialized = false;
  static ReactiveStore? _store;

  const Vortex({super.key, required this.child, this.configPath});

  // Initialize the vortex project Directory
  static Directory? projectDirectory = Directory.current;

  /// Get the global store instance
  static ReactiveStore get store {
    if (!_isInitialized) {
      throw StateError(
        'Vortex must be initialized before use. Call Vortex.initialize() first.',
      );
    }
    return _store!;
  }

  /// Register a custom composable
  static void registerComposable<T>(String name, T composable) {
    try {
      ComposableRegistry.register<T>(name, composable);
      Log.i('Registered composable: $name');
    } catch (e) {
      Log.e('Error registering composable: $e');
    }
  }

  /// Get a registered composable
  static dynamic getComposable(String name) {
    return ComposableRegistry.get(name);
  }

  /// Register a plugin with the framework
  static dynamic registerPlugin(Plugin plugin) {
    try {
      PluginRegistry.register(plugin);
      //add a feature to register plugin helpers mad made it avaliable to the application
      // eg usage on example app : VortexPlugins.<plugin_name>.<helper_name>(args)
      Log.i('Registered plugin: ${plugin.name}');
    } catch (e) {
      Log.e('Error registering plugin: $e');
    }
  }

  /// Get a registered plugin
  static dynamic getPlugin(String name) {
    return PluginRegistry.getPlugin(name);
  }

  /// Register a component
  static void registerComponent<T extends Widget>(
    String name,
    Widget Function(Map<String, dynamic>) builder,
  ) {
    ComponentRegistry.register<T>(name, builder);
    Log.i('Registered component: $name');
  }

  /// Get a registered component
  static dynamic getComponent(String name) {
    return ComponentRegistry.get(name);
  }

  /// Notify plugins of app start
  static Future<void> notifyAppStart(BuildContext context) async {
    try {
      await PluginRegistry.notifyAppStart(context);
    } catch (e) {
      Log.e('Error notifying plugins of app start: $e');
    }
  }

  /// Notify plugins of app close
  static Future<void> notifyAppClose() async {
    try {
      await PluginRegistry.notifyAppClose();
    } catch (e) {
      Log.e('Error notifying plugins of app close: $e');
    }
  }

  /// Initialize FlutterWind framework
  static Future<void> initialize({
    String? configPath,
    bool logEnabled = false,
  }) async {
    if (_isInitialized) {
      Log.i('Vortex already initialized, skipping...');
      return;
    }

    try {
      Log.i('Initializing Vortex...');
      Log.i('Project directory: ${Directory.current.path}');

      // Load configuration
      final config = await _loadConfig(configPath);
      Log.i('Configuration loaded: ${config.toString()}');

      // Initialize store with persistence
      await ReactiveStore.initialize(
        persistentEnabled: config.storePersistent,
        logEnabled: config.storeLog,
      );

      // Create store instance after initialization
      _store = ReactiveStore();

      // Test persistence if enabled
      if (config.storePersistent) {
        Log.i('Testing store persistence...');
        await _store!.setState('test_persistence', true, persistent: true);
        final testValue = _store!.getState<bool>(
          'test_persistence',
          persistent: true,
        );
        Log.i('Persistence test value: $testValue');

        // Set initial theme value if not exists
        if (_store!.getState<bool>('theme_dark_mode', persistent: true) ==
            null) {
          Log.i('Setting initial theme value');
          await _store!.setState('theme_dark_mode', false, persistent: true);
        }
      }

      _isInitialized = true;
      Log.i('Vortex initialization completed');
    } catch (e) {
      Log.e('Error initializing Vortex: $e');
      rethrow;
    }
  }

  static Future<VortexConfig> _loadConfig(String? configPath) async {
    // Ensure Flutter bindings are initialized
    WidgetsFlutterBinding.ensureInitialized();

    final configFile = File(configPath ?? 'vortex.config.yaml');
    if (!await configFile.exists()) {
      Log.w(
        'vortex.config.yaml not found in ${configFile.path}, using default configuration',
      );
      return VortexConfig.defaultConfig();
    }

    final yamlString = await configFile.readAsString();
    Log.i('Loaded config file: $yamlString');
    final yaml = loadYaml(yamlString) as YamlMap;
    final config = VortexConfig.fromYaml(yaml);
    Log.i('Parsed config: ${config.toString()}');
    return config;
  }

  @override
  State<Vortex> createState() => _VortexState();
}

class _VortexState extends State<Vortex> with WidgetsBindingObserver {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await Vortex.initialize(configPath: widget.configPath);
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      Log.e('Error initializing Vortex: $e');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    return ErrorBoundary(
      onError: (error, stackTrace) {
        Log.e('Error in Vortex app: $error');
        Log.d('Stack trace: $stackTrace');
      },
      child: ReactiveProvider(
        store: ReactiveStore(),
        child: VortexComponentProvider(
          components: ComponentRegistry.components,
          child: widget.child,
        ),
      ),
    );
  }
}
