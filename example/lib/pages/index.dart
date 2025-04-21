import 'package:flutter/material.dart';
import 'package:vortex/vortex.dart';
import 'package:flutterwind_core/flutterwind.dart';

/// LoginPage page
@VortexPage('/')
class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with CompositionMixin {
  @override
  Widget build(BuildContext context) {
    final useThemeComposable = Vortex.getComposable('useTheme');
    final themeState = useThemeComposable(context);
    print("themeState :: ${themeState.toggleTheme()}");

    final isDarkMode = themeState.isDarkMode;

    return ReactiveBuilder(
      dependencies: [isDarkMode], // Add the isDarkMode state to the dependencies list
      builder: (context) {
        return Scaffold(
          body: Center(
            child: Text("Toggle Theme ${isDarkMode.value}")
                .className('text-black')
                .withGestures(
                  onTap: () {
                    themeState.toggleTheme();
                  },
                ),
          ).className('bg-white dark:bg-red-400'),
        );
      },
    );
  }
}
