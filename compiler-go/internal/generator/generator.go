package generator

import (
	"compiler-go/internal/ast"
	"fmt"
	"os"
	"path/filepath"
)

// Generator converts Flutter widgets to web output
type Generator struct {
	jsGen  *JSGenerator
	cssGen *CSSGenerator
}

// NewGenerator creates a new generator
func NewGenerator() *Generator {
	return &Generator{
		jsGen:  NewJSGenerator(),
		cssGen: NewCSSGenerator(),
	}
}

// Generate creates web output from a widget tree
func (g *Generator) Generate(widgetTree *ast.WidgetTree, outputDir string) error {
	// Create output directory if it doesn't exist
	if err := os.MkdirAll(outputDir, 0755); err != nil {
		return fmt.Errorf("failed to create output directory: %v", err)
	}

	// Generate JavaScript code
	jsCode, err := g.jsGen.Generate(widgetTree)
	if err != nil {
		return fmt.Errorf("failed to generate JavaScript: %v", err)
	}

	// Generate CSS code
	cssCode := g.cssGen.Generate()

	// Write JavaScript file
	jsPath := filepath.Join(outputDir, "app.js")
	if err := os.WriteFile(jsPath, []byte(jsCode), 0644); err != nil {
		return fmt.Errorf("failed to write JavaScript file: %v", err)
	}

	// Write CSS file
	cssPath := filepath.Join(outputDir, "styles.css")
	if err := os.WriteFile(cssPath, []byte(cssCode), 0644); err != nil {
		return fmt.Errorf("failed to write CSS file: %v", err)
	}

	// Write HTML file
	htmlCode := `<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Flutter Web App</title>
    <link rel="stylesheet" href="styles.css">
    <link href="https://fonts.googleapis.com/css2?family=Roboto:wght@300;400;500;700&display=swap" rel="stylesheet">
</head>
<body>
    <div class="app"></div>
    <script src="app.js"></script>
</body>
</html>`

	htmlPath := filepath.Join(outputDir, "index.html")
	if err := os.WriteFile(htmlPath, []byte(htmlCode), 0644); err != nil {
		return fmt.Errorf("failed to write HTML file: %v", err)
	}

	return nil
}
