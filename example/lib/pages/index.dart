import 'package:example/generated/plugins.vortex.g.dart';
import 'package:flutter/material.dart';
import 'package:vortex/vortex.dart';
import 'package:flutterwind_core/flutterwind.dart';

/// LoginPage page
@VortexPage('/')
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with CompositionMixin {
  @override
  Widget build(BuildContext context) {
    final logger = VortexPlugins.instance.logger;
    logger.info('User clicked the button hello');

    // Get the theme state
    final themeState = useTheme();

    return ReactiveBuilder(
      dependencies: [themeState.isDarkMode],
      builder: (context) {
        return Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Current Theme: ${themeState.isDarkMode.value ? 'Dark' : 'Light'}",
                ).className('text-black dark:text-white'),

                SizedBox(height: 20),

                ElevatedButton(
                  onPressed: () {
                    themeState.toggleDarkMode();
                  },
                  child: Text('Toggle Theme'),
                ),

                SizedBox(height: 10),

                ElevatedButton(
                  onPressed: () {
                    themeState.setDarkMode(true);
                  },
                  child: Text('Set Dark Mode'),
                ),

                SizedBox(height: 10),

                ElevatedButton(
                  onPressed: () {
                    themeState.setDarkMode(false);
                  },
                  child: Text('Set Light Mode'),
                ),
              ],
            ),
          ).className('bg-white dark:bg-gray-900'),
        );
      },
    );
  }
}
