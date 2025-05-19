package main

import (
	"flag"
	"fmt"
	"os"
	"path/filepath"

	"compiler-go/internal/config"
	"compiler-go/internal/generator"
	"compiler-go/internal/parser"
)

func main() {
	// Parse command line flags
	sourceDir := flag.String("source", "", "Source directory containing Flutter project")
	outputDir := flag.String("output", "dist", "Output directory for generated files")
	flag.Parse()

	// Validate source directory
	if *sourceDir == "" {
		fmt.Println("Error: source directory is required")
		flag.Usage()
		os.Exit(1)
	}

	// Load config from project root
	cfg, err := config.LoadConfig(*sourceDir)
	if err != nil {
		fmt.Printf("Error loading config: %v\n", err)
		os.Exit(1)
	}

	// Use output directory from config if specified
	if cfg.Compiler.OutputDir != "" {
		*outputDir = cfg.Compiler.OutputDir
	}

	// Create output directory if it doesn't exist
	if err := os.MkdirAll(*outputDir, 0755); err != nil {
		fmt.Printf("Error creating output directory: %v\n", err)
		os.Exit(1)
	}

	// Initialize parser and generator
	parser := parser.NewParser()
	jsGenerator := generator.NewJSGenerator()
	jsGenerator.SetSourceDir(*sourceDir)

	// Process main.dart first
	mainDartPath := filepath.Join(*sourceDir, "main.dart")
	if _, err := os.Stat(mainDartPath); err == nil {
		// Read main.dart
		source, err := os.ReadFile(mainDartPath)
		if err != nil {
			fmt.Printf("Error reading main.dart: %v\n", err)
			os.Exit(1)
		}

		// Parse main.dart
		widgetTree, err := parser.Parse(string(source))
		if err != nil {
			fmt.Printf("Error parsing main.dart: %v\n", err)
			os.Exit(1)
		}

		// Generate JavaScript code
		jsCode, err := jsGenerator.Generate(widgetTree)
		if err != nil {
			fmt.Printf("Error generating code for main.dart: %v\n", err)
			os.Exit(1)
		}

		// Write main.js
		mainJsPath := filepath.Join(*outputDir, "main.js")
		if err := os.WriteFile(mainJsPath, []byte(jsCode), 0644); err != nil {
			fmt.Printf("Error writing main.js: %v\n", err)
			os.Exit(1)
		}
		fmt.Printf("Generated: %s\n", mainJsPath)
	}

	// Process lib directory
	libDir := filepath.Join(*sourceDir, "lib")
	if _, err := os.Stat(libDir); err != nil {
		fmt.Printf("Warning: lib directory not found: %v\n", err)
		return
	}

	// Walk through lib directory
	err = filepath.Walk(libDir, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}

		// Skip directories and non-Dart files
		if info.IsDir() || filepath.Ext(path) != ".dart" {
			return nil
		}

		// Read source file
		source, err := os.ReadFile(path)
		if err != nil {
			return fmt.Errorf("error reading file %s: %v", path, err)
		}

		// Parse the file
		widgetTree, err := parser.Parse(string(source))
		if err != nil {
			return fmt.Errorf("error parsing file %s: %v", path, err)
		}

		// Generate JavaScript code
		jsCode, err := jsGenerator.Generate(widgetTree)
		if err != nil {
			return fmt.Errorf("error generating code for %s: %v", path, err)
		}

		// Create output file path
		relPath, err := filepath.Rel(libDir, path)
		if err != nil {
			return fmt.Errorf("error getting relative path: %v", err)
		}
		outputPath := filepath.Join(*outputDir, "lib", relPath[:len(relPath)-5]+".js")

		// Create output directory if it doesn't exist
		if err := os.MkdirAll(filepath.Dir(outputPath), 0755); err != nil {
			return fmt.Errorf("error creating output directory: %v", err)
		}

		// Write generated code to file
		if err := os.WriteFile(outputPath, []byte(jsCode), 0644); err != nil {
			return fmt.Errorf("error writing file %s: %v", outputPath, err)
		}

		fmt.Printf("Generated: %s\n", outputPath)
		return nil
	})

	if err != nil {
		fmt.Printf("Error processing files: %v\n", err)
		os.Exit(1)
	}

	fmt.Println("Compilation completed successfully!")
}
