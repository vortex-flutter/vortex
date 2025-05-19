import 'package:flutter/material.dart';

class MainLayout extends StatelessWidget {
  final Widget child;

  const MainLayout({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vortex App'),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () => Navigator.pushNamed(context, '/'),
          ),
          IconButton(
            icon: const Icon(Icons.info),
            onPressed: () => Navigator.pushNamed(context, '/about'),
          ),
          IconButton(
            icon: const Icon(Icons.contact_mail),
            onPressed: () => Navigator.pushNamed(context, '/contact'),
          ),
        ],
      ),
      body: child,
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/dashboard'),
        child: const Icon(Icons.dashboard),
      ),
    );
  }
}
