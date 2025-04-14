import 'package:flutter/material.dart';
import 'package:vortex/vortex.dart';

@Middleware(name: 'auth')
class AuthMiddleware implements VortexMiddleware {
  @override
  Future<bool> execute(BuildContext context, String route) async {
    Log.w('context $context');
    // Simulate checking authentication status
    return true;
  }
}
