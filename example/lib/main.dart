import 'dart:io';
import 'package:example/middleware/auth_middleware.dart';
import 'package:example/plugins/logger_plugin.dart';
import 'package:flutter/material.dart';
import 'package:flutterwind_core/flutterwind.dart';
import 'package:vortex/vortex.dart';
import 'package:example/generated/routes.dart';

void main() async {
  Vortex.projectDirectory = Directory(
    '/Volumes/EVILRATT/Innovative Projects/vortex/example',
  );
  await VortexRouter.discoverRoutes(
    projectDirectory: Directory(
      '/Volumes/EVILRATT/Innovative Projects/vortex/example',
    ),
  );
  registerLoggerPlugin();
  initializeRoutes();
  MiddlewareRegistry.register('auth', AuthMiddleware());
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with CompositionMixin {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    final themeState = useTheme(
      lightTheme: ThemeData.light().copyWith(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData.dark().copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      initialDarkMode: false,
    );

    // Set up watchers
    watch(themeState.isDarkMode, () => themeState.isDarkMode.value, (
      newValue,
      oldValue,
    ) {
      Log.i(
        'Theme changed from ${oldValue! ? "dark" : "light"} to ${newValue ? "dark" : "light"}',
      );
    });

    // Set up lifecycle hooks
    onMounted(() {
      Log.i('App mounted');
    });

    return Vortex(
      child: ReactiveBuilder(
        dependencies: [themeState.theme, themeState.isDarkMode],
        builder: (context) {
          return FlutterWind(
            showDevTools: true,
            title: 'FlutterWind Demo',
            themeMode:
                themeState.isDarkMode.value ? ThemeMode.dark : ThemeMode.light,
            initialRoute: '/',
            onGenerateInitialRoutes:
                (initialRoute) => [
                  VortexRouter.initialRouteHandler(
                    RouteSettings(name: initialRoute),
                  ),
                ],
            onGenerateRoute: VortexRouter.onGenerateRoute,
          );
        },
      ),
    );
  }
}
