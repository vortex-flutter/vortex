# Flutter HTML Compiler

A Go-based compiler that converts Flutter UI code (written in Dart) into static HTML, CSS, and JavaScript files.

## Features

- Parse Dart files containing Flutter widget trees
- Convert Flutter widgets to equivalent HTML elements
- Generate corresponding CSS styles
- Generate JavaScript for interactive behaviors
- Support for basic Flutter widgets and layouts

## Installation

```bash
go install github.com/yourusername/flutter-html-compiler@latest
```

## Usage

```bash
# Basic usage
flutter-html-compiler -i input.dart -o dist

# Options
-i, --input    Input Dart file path (required)
-o, --output   Output directory for generated files (default: "dist")
```

## Example

Input Dart file (`sample.dart`):
```dart
import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      home: Scaffold(
        appBar: AppBar(title: Text('Demo')),
        body: Center(child: Text('Hello, World!')),
      ),
    );
  }
}
```

Run the compiler:
```bash
flutter-html-compiler -i sample.dart -o dist
```

This will generate:
- `dist/index.html`
- `dist/styles.css`
- `dist/app.js`

## Project Structure

```
compiler-go/
├── cmd/
│   └── main.go           # CLI entry point
├── internal/
│   ├── parser/           # Dart file parsing
│   ├── mapper/           # Widget to HTML mapping
│   └── generator/        # HTML/CSS/JS generation
├── pkg/
│   ├── ast/             # Abstract Syntax Tree types
│   └── utils/           # Utility functions
└── examples/            # Example Dart files
```

## Development

1. Clone the repository
2. Install dependencies:
   ```bash
   go mod tidy
   ```
3. Build the project:
   ```bash
   go build -o flutter-html-compiler cmd/main.go
   ```

## License

MIT 