import 'package:flutter/material.dart';
import 'package:vortex/vortex.dart';
import 'package:flutterwind_core/flutterwind.dart';

/// LoginPage page
@VortexPage('/login')
class LoginPage extends StatelessWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        child: Text("Login"),
      ),
    ).className('bg-red-500');
  }
}
