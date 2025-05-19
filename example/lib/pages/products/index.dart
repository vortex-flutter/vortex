import 'package:example/generated/components.vortex.g.dart';
import 'package:flutter/material.dart';
import 'package:flutterwind_core/flutterwind.dart';
import 'package:vortex/vortex.dart';

/// ProductPage page
@VortexPage('/products')
class ProductPage extends StatelessWidget {
  const ProductPage({super.key});

  @override
  Widget build(BuildContext context) {
    final productCard = VortexComponent.instance.productCard;
    return Scaffold(
      appBar: AppBar(title: const Text('Products')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          productCard({
            'title': 'Premium Headphones',
            'price': 199.99,
            'imageUrl': 'https://example.com/images/headphones.jpg',
            'onTap': () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Headphones selected')),
              );
            },
          }),
          const SizedBox(height: 16),
          productCard({
            'title': 'Wireless Keyboard',
            'price': 89.99,
            'imageUrl': 'https://example.com/images/keyboard.jpg',
          }),
          const SizedBox(height: 16),
          productCard({
            'title': 'Smart Watch',
            'price': 249.99,
            'imageUrl': 'https://example.com/images/watch.jpg',
          }),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to add product page
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
