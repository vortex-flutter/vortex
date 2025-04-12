import 'package:flutter/widgets.dart';

/// A provider that makes components available to the widget tree
class VortexComponentProvider extends InheritedWidget {
  final Map<String, Widget Function(Map<String, dynamic>)> components;

  const VortexComponentProvider({
    super.key,
    required this.components,
    required super.child,
  });

  static VortexComponentProvider? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<VortexComponentProvider>();
  }

  @override
  bool updateShouldNotify(VortexComponentProvider oldWidget) {
    return components != oldWidget.components;
  }
}

/// A builder that creates a component from the registry
class ComponentBuilder extends StatelessWidget {
  final String name;
  final Map<String, dynamic> props;

  const ComponentBuilder({
    super.key,
    required this.name,
    required this.props,
  });

  @override
  Widget build(BuildContext context) {
    final provider = VortexComponentProvider.of(context);
    
    if (provider == null) {
      throw Exception('ComponentBuilder must be used within a FlutterWindComponentProvider');
    }
    
    final builder = provider.components[name];
    
    if (builder == null) {
      throw Exception('Component not found: $name');
    }
    
    return builder(props);
  }
}