import 'dart:io';

import 'package:example/middleware/auth_middleware.dart';
import 'package:flutter/material.dart';
import 'package:flutterwind_core/flutterwind.dart';
import 'package:vortex/vortex.dart';

void main() async {
  await VortexRouter.discoverRoutes(
    projectDirectory: Directory(
      '/Users/yashkumar/Documents/Projects/vortex/example',
    ),
  );

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
    final isDarkMode = useRef<bool>('isDarkMode', false);

    // Set up watchers
    watch(isDarkMode, () => isDarkMode.value, (newValue, oldValue) {
      Log.i(
        'Theme changed from ${oldValue! ? "dark" : "light"} to ${newValue ? "dark" : "light"}',
      );
    });

    // Set up lifecycle hooks
    onMounted(() {
      Log.i('App mounted');
    });

    return Vortex(
      child: FlutterWind(
        child: MaterialApp(
          title: 'Vortex Demo',
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
          themeMode: isDarkMode.value ? ThemeMode.dark : ThemeMode.light,
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
