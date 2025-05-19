package main

import (
	"flag"
	"fmt"
	"io/ioutil"
	"os"
	"path/filepath"

	"compiler-go/internal/generator"
	"compiler-go/internal/parser"
)

func main() {
	// Parse command line arguments
	inputFile := flag.String("i", "", "Input Dart file")
	outputDir := flag.String("o", "dist", "Output directory")
	flag.Parse()

	if *inputFile == "" {
		fmt.Println("Error: Input file is required")
		flag.Usage()
		os.Exit(1)
	}

	// Create output directory if it doesn't exist
	if err := os.MkdirAll(*outputDir, 0755); err != nil {
		fmt.Printf("Error creating output directory: %v\n", err)
		os.Exit(1)
	}

	// Read input file
	content, err := ioutil.ReadFile(*inputFile)
	if err != nil {
		fmt.Printf("Error reading input file: %v\n", err)
		os.Exit(1)
	}

	// Parse the Dart code
	p := parser.NewParser()
	widgetTree, err := p.Parse(string(content))
	if err != nil {
		fmt.Printf("Error parsing Dart code: %v\n", err)
		os.Exit(1)
	}

	// Generate JavaScript code
	jsGen := generator.NewJSGenerator()
	jsCode, err := jsGen.Generate(widgetTree)
	if err != nil {
		fmt.Printf("Error generating JavaScript: %v\n", err)
		os.Exit(1)
	}

	// Copy template files
	templateFiles := map[string]string{
		"index.html": "templates/index.html",
		"styles.css": "templates/styles.css",
		"app.js":     "templates/app.js",
	}

	for outputFile, templateFile := range templateFiles {
		content, err := ioutil.ReadFile(templateFile)
		if err != nil {
			fmt.Printf("Error reading template file %s: %v\n", templateFile, err)
			os.Exit(1)
		}

		outputPath := filepath.Join(*outputDir, outputFile)
		if err := ioutil.WriteFile(outputPath, content, 0644); err != nil {
			fmt.Printf("Error writing output file %s: %v\n", outputPath, err)
			os.Exit(1)
		}
	}

	// Write generated JavaScript
	outputPath := filepath.Join(*outputDir, "app.js")
	if err := ioutil.WriteFile(outputPath, []byte(jsCode), 0644); err != nil {
		fmt.Printf("Error writing JavaScript file: %v\n", err)
		os.Exit(1)
	}

	fmt.Printf("Successfully compiled to %s\n", *outputDir)
}
