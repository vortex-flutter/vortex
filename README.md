# Vortex

<p align="center">
  <img src="https://raw.githubusercontent.com/vortex-flutter/vortex/main/assets/vortex_logo.png" alt="Vortex Logo" width="200"/>
</p>

<p align="center">
  <a href="https://pub.dev/packages/vortex"><img src="https://img.shields.io/pub/v/vortex.svg" alt="Pub"></a>
  <a href="https://github.com/vortex-flutter/vortex/actions"><img src="https://github.com/vortex-flutter/vortex/workflows/tests/badge.svg" alt="Build Status"></a>
  <a href="https://opensource.org/licenses/MIT"><img src="https://img.shields.io/badge/license-MIT-purple.svg" alt="License: MIT"></a>
</p>

**Vortex** is a powerful Flutter framework that brings the convenience and structure of Nuxt.js to Flutter development. It provides automatic routing, component management, plugin architecture, and more to streamline your Flutter development workflow.

## 🚀 Features

- **📁 File-based Routing**: Automatically generate routes based on your file structure in the pages directory
- **🧹 Component System**: Create and register reusable components with a simple API
- **🔌 Plugin Architecture**: Extend functionality with a flexible plugin system
- **⚡ Reactive State Management**: Built-in reactive state management solution
- **🔄 Middleware Support**: Add middleware to handle navigation and requests
- **🛠️ CLI Tools**: Command-line tools for generating pages, components, and more

<p align="center">
  <img src="https://raw.githubusercontent.com/vortex-flutter/vortex/main/assets/vortex_architecture.png" alt="Vortex Architecture" width="600"/>
</p>

## 📜 Table of Contents

- [Installation](#-installation)
- [Basic Setup](#-basic-setup)
- [Routing](#-routing)
- [Components](#-components)
- [State Management](#-state-management)
- [Plugins](#-plugins)
- [Middleware](#-middleware)
- [CLI Commands](#-cli-commands)
- [Examples](#-examples)
- [Contributing](#-contributing)
- [License](#-license)

## 📅 Installation

Add Vortex to your `pubspec.yaml`:

```yaml
dependencies:
  vortex: ^0.0.1
```

Run `flutter pub get` to install the package.

## 🔧 Basic Setup

Initialize Vortex in your `main.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:vortex/vortex.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Vortex.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Vortex(
      child: MaterialApp(
        title: 'Vortex App',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
        ),
        onGenerateRoute: VortexRouter.onGenerateRoute,
        initialRoute: '/',
      ),
    );
  }
}
```

Create a new Vortex project with the CLI:

```bash
flutter pub run vortex create --name=my_app
```

This will create a new Flutter project with the Vortex folder structure:

```plaintext
lib/
  ├── pages/           # Route pages
  ├── components/      # Reusable UI components
  ├── layouts/         # Page layouts
  ├── middleware/      # Navigation middleware
  ├── plugins/         # App plugins
  ├── store/           # State management
  ├── assets/          # Images, fonts, etc.
  └── generated/       # Auto-generated code
```

## 🧭 Routing

Vortex uses a file-based routing system similar to Nuxt.js.

### Basic Routes

```
lib/pages/index.dart      → /
lib/pages/about.dart      → /about
lib/pages/contact.dart    → /contact
```

### Nested Routes

```
lib/pages/users/index.dart        → /users
lib/pages/users/profile.dart      → /users/profile
```

### Dynamic Routes

```
lib/pages/users/[id].dart         → /users/:id
lib/pages/blog/[...slug].dart     → /blog/* (catch-all route)
```

### Creating a Page

```dart
import 'package:flutter/material.dart';
import 'package:vortex/vortex.dart';

@VortexPage('/about')
class AboutPage extends StatelessWidget {
  const AboutPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: const Center(child: Text('About Page')),
    );
  }
}
```

### Generating a Page with CLI

```bash
flutter pub run vortex page --name=contact --type=stateless
```

### Accessing Route Parameters

```dart
@VortexPage('/users/:id')
class UserDetailPage extends StatelessWidget {
  const UserDetailPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final params = VortexRouter.of(context).params;
    final userId = params['id'] ?? 'unknown';
    return Scaffold(
      appBar: AppBar(title: Text('User $userId')),
      body: Center(child: Text('User ID: $userId')),
    );
  }
}
```

## 🧹 Components

Vortex provides a component system that allows you to create reusable UI components.

### Creating a Component

```dart
// lib/components/button.dart
import 'package:flutter/material.dart';
import 'package:vortex/vortex.dart';

@Component('Button')
class Button extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Color? color;

  const Button({
    Key? key,
    required this.text,
    required this.onPressed,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: color != null ? ElevatedButton.styleFrom(backgroundColor: color) : null,
      child: Text(text),
    );
  }
}
```

### Registering Components

```bash
flutter pub run vortex components
```

### Using Components

```dart
context.component('Button')({
  'text': 'Click Me',
  'onPressed': () => print('Button clicked'),
  'color': Colors.blue,
})
```

## ⚡ State Management

### Creating a Store

```dart
import 'package:vortex/vortex.dart';

class CounterState {
  final int count;
  CounterState({this.count = 0});

  CounterState copyWith({int? count}) {
    return CounterState(count: count ?? this.count);
  }
}

final counterStore = ReactiveStore<CounterState>(CounterState());

void increment() => counterStore.update((state) => state.copyWith(count: state.count + 1));
void decrement() => counterStore.update((state) => state.copyWith(count: state.count - 1));
```

### Using the Store

```dart
ReactiveBuilder<CounterState>(
  store: counterStore,
  builder: (context, state) {
    return Text('Count: ${state.count}');
  },
)
```

## 🔌 Plugins

Coming soon.

## 🔄 Middleware

Coming soon.

## 🛠️ CLI Commands

- `vortex create` - Create new Vortex project
- `vortex page` - Generate new page
- `vortex component` - Generate new component

## 📍 Examples

Coming soon.

## 💪 Contributing

Pull requests welcome! For major changes, please open an issue first to discuss what you would like to change.

## 📚 License

MIT License.

---

Made with ❤️ by the Vortex team and CodeSyncr.