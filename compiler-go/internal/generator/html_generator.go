package generator

import (
	"fmt"
	"strings"
	"text/template"
)

// HTMLGenerator generates HTML output
type HTMLGenerator struct {
	template *template.Template
}

// NewHTMLGenerator creates a new HTML generator
func NewHTMLGenerator() *HTMLGenerator {
	return &HTMLGenerator{
		template: template.Must(template.New("html").Parse(`
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Flutter Web App</title>
    <link rel="stylesheet" href="styles.css">
</head>
<body>
    <div class="app"></div>
    <script src="app.js"></script>
</body>
</html>
`)),
	}
}

// Generate creates HTML output
func (g *HTMLGenerator) Generate() (string, error) {
	var output strings.Builder
	if err := g.template.Execute(&output, nil); err != nil {
		return "", fmt.Errorf("failed to generate HTML: %v", err)
	}
	return output.String(), nil
}
