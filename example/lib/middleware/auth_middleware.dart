import 'package:flutter/material.dart';
import 'package:vortex/vortex.dart';

@Middleware(name: 'auth')
class AuthMiddleware implements VortexMiddleware {
  @override
  Future<bool> execute(BuildContext context, String route) async {
    Log.w('context $context');
    // Simulate checking authentication status
    final isAuthenticated = await _checkAuthStatus();
    if (!isAuthenticated) {
      try {
        Log.i("isAuthenticated: $isAuthenticated");

        if (_canNavigate(context)) {
          // User is not authenticated, redirect to login page
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please login to access this page')),
          );

          // Navigate to login page
          VortexRouter.navigateTo(context, '/login');
        } else {
          // We're in the initial route setup, can't navigate yet
          Log.i(
              'Cannot navigate from this context - middleware will block navigation');
        }
      } catch (e) {
        Log.e('Error in auth middleware: $e');
      }

      // Return false to prevent original navigation
      return false;
    }

    // User is authenticated, allow navigation to proceed
    return true;
  }

  // Helper method to check if navigation is possible
  bool _canNavigate(BuildContext context) {
    try {
      return Navigator.maybeOf(context) != null;
    } catch (e) {
      return false;
    }
  }

  Future<bool> _checkAuthStatus() async {
    // In a real app, you would check secure storage, API token validity, etc.
    // This is just a simple example that returns false 50% of the time
    await Future.delayed(
        const Duration(milliseconds: 300)); // Simulate API call
    return false;
  }
}
