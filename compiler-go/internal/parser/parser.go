package parser

import (
	"fmt"
	"regexp"
	"strings"

	"compiler-go/internal/ast"
)

// Parser represents a Dart file parser
type Parser struct {
	// Add any parser-specific fields here
}

// NewParser creates a new Parser instance
func NewParser() *Parser {
	return &Parser{}
}

// Parse parses Dart code and returns a widget tree
func (p *Parser) Parse(content string) (*ast.WidgetTree, error) {
	// Find the build method
	buildMethod := p.findBuildMethod(content)
	if buildMethod == "" {
		return nil, fmt.Errorf("build method not found")
	}

	// Extract the widget tree from the build method
	widgetTree, err := p.extractWidgetTree(buildMethod)
	if err != nil {
		return nil, fmt.Errorf("failed to extract widget tree: %v", err)
	}

	return widgetTree, nil
}

// findBuildMethod finds the build method in the Dart code
func (p *Parser) findBuildMethod(content string) string {
	// Look for the build method (multi-line)
	buildRegex := regexp.MustCompile(`Widget\s+build\s*\(\s*BuildContext\s+context\s*\)\s*{([\s\S]*?)\n}`)
	matches := buildRegex.FindStringSubmatch(content)
	if len(matches) < 2 {
		return ""
	}
	fmt.Println("=== buildMethod ===")
	fmt.Println(matches[1])
	return matches[1]
}

// extractWidgetTree extracts the widget tree from the build method
func (p *Parser) extractWidgetTree(buildMethod string) (*ast.WidgetTree, error) {
	// Find the return statement (multi-line)
	returnRegex := regexp.MustCompile(`return\s+([\s\S]+?);`)
	matches := returnRegex.FindStringSubmatch(buildMethod)
	if len(matches) < 2 {
		return nil, fmt.Errorf("return statement not found")
	}
	fmt.Println("=== returnExpr ===")
	fmt.Println(matches[1])

	// Parse the widget tree
	widgetNode := p.parseWidgetExpression(matches[1])
	if widgetNode == nil {
		return nil, fmt.Errorf("failed to parse widget expression")
	}

	return &ast.WidgetTree{Root: widgetNode}, nil
}

// parseWidgetExpression parses a widget expression with robust parenthesis matching
func (p *Parser) parseWidgetExpression(expr string) *ast.WidgetNode {
	expr = strings.TrimSpace(expr)
	if expr == "" {
		return nil
	}

	// Ignore 'const' keyword
	if strings.HasPrefix(expr, "const ") {
		expr = strings.TrimSpace(expr[5:])
	}

	// Support chained constructors: Widget.namedConstructor(...)
	parenIdx := strings.Index(expr, "(")
	if parenIdx == -1 {
		return nil
	}
	widgetName := strings.TrimSpace(expr[:parenIdx])
	widgetName = strings.ReplaceAll(widgetName, ".", "_") // e.g., Image.network -> Image_network

	// Find the matching closing parenthesis for the first '('
	argsStart := parenIdx + 1
	parenDepth := 1
	argsEnd := -1
	for i := argsStart; i < len(expr); i++ {
		c := expr[i]
		if c == '(' {
			parenDepth++
		} else if c == ')' {
			parenDepth--
			if parenDepth == 0 {
				argsEnd = i
				break
			}
		}
	}
	if argsEnd == -1 {
		return nil // Unmatched parenthesis
	}
	args := expr[argsStart:argsEnd]

	widget := &ast.WidgetNode{
		Name:       widgetName,
		Properties: make(map[string]ast.PropertyValue),
		Children:   make([]*ast.WidgetNode, 0),
	}

	// Split arguments at top level only
	argsList := splitArgsTopLevel(args)
	for _, arg := range argsList {
		arg = strings.TrimSpace(arg)
		if arg == "" {
			continue
		}
		// Parse key: value
		kv := strings.SplitN(arg, ":", 2)
		if len(kv) != 2 {
			continue
		}
		propName := strings.TrimSpace(kv[0])
		propValue := strings.TrimSpace(kv[1])

		// Skip function properties (e.g., errorBuilder: (context, error, stackTrace) { ... })
		if strings.HasPrefix(propValue, "(") && strings.Contains(propValue, ") {") {
			continue
		}

		// Special handling for children: [...]
		if propName == "children" && strings.HasPrefix(propValue, "[") && strings.HasSuffix(propValue, "]") {
			children := p.parseWidgetList(propValue)
			widget.Children = append(widget.Children, children...)
			continue
		}

		// Handle nested widget
		if widgetExpr := p.parseWidgetExpression(propValue); widgetExpr != nil {
			widget.Properties[propName] = ast.PropertyValue{Widget: widgetExpr}
			continue
		}
		// Handle list (not children)
		if strings.HasPrefix(propValue, "[") && strings.HasSuffix(propValue, "]") {
			// For other list properties, not 'children'
			continue
		}
		// Handle string interpolation: replace with placeholder
		if strings.Contains(propValue, "$") {
			placeholder := "INTERPOLATED_STRING"
			widget.Properties[propName] = ast.PropertyValue{String: &placeholder}
			continue
		}
		// Handle string
		if (strings.HasPrefix(propValue, "'") && strings.HasSuffix(propValue, "'")) || (strings.HasPrefix(propValue, "\"") && strings.HasSuffix(propValue, "\"")) {
			value := strings.Trim(propValue, "'\"")
			widget.Properties[propName] = ast.PropertyValue{String: &value}
			continue
		}
		// Handle expressions like Theme.of(context), Colors.grey[300], BoxFit.cover
		if strings.Contains(propValue, ".") || strings.Contains(propValue, "[") {
			placeholder := propValue
			widget.Properties[propName] = ast.PropertyValue{String: &placeholder}
			continue
		}
		// Fallback: treat as string
		widget.Properties[propName] = ast.PropertyValue{String: &propValue}
	}

	return widget
}

// parseWidgetList parses a list of widgets or values
func (p *Parser) parseWidgetList(list string) []*ast.WidgetNode {
	list = strings.TrimSpace(list)
	list = strings.TrimPrefix(list, "[")
	list = strings.TrimSuffix(list, "]")

	items := splitArgsTopLevel(list)
	widgets := make([]*ast.WidgetNode, 0)
	for _, item := range items {
		item = strings.TrimSpace(item)
		if item == "" {
			continue
		}
		if widget := p.parseWidgetExpression(item); widget != nil {
			widgets = append(widgets, widget)
		}
	}
	return widgets
}

// splitArgsTopLevel splits a comma-separated argument string at the top level only
func splitArgsTopLevel(s string) []string {
	var args []string
	var current strings.Builder
	paren, bracket := 0, 0
	for i := 0; i < len(s); i++ {
		c := s[i]
		switch c {
		case '(':
			paren++
		case ')':
			paren--
		case '[':
			bracket++
		case ']':
			bracket--
		case ',':
			if paren == 0 && bracket == 0 {
				args = append(args, current.String())
				current.Reset()
				continue
			}
		}
		current.WriteByte(c)
	}
	if current.Len() > 0 {
		args = append(args, current.String())
	}
	return args
}

// parsePropertyValue converts a property value to a PropertyValue
func (p *Parser) parsePropertyValue(value *ast.PropertyValue) error {
	switch {
	case value.String != nil:
		*value = ast.PropertyValue{String: value.String}
	case value.Number != nil:
		*value = ast.PropertyValue{Number: value.Number}
	case value.Boolean != nil:
		*value = ast.PropertyValue{Boolean: value.Boolean}
	case value.Widget != nil:
		widget, err := p.parseWidget(value.Widget)
		if err != nil {
			return err
		}
		*value = ast.PropertyValue{Widget: widget}
	case value.List != nil:
		items := make([]ast.PropertyValue, len(value.List))
		for i, item := range value.List {
			if err := p.parsePropertyValue(&item); err != nil {
				return err
			}
			items[i] = item
		}
		*value = ast.PropertyValue{List: items}
	case value.Style != nil:
		styles := make(map[string]string)
		for k, v := range value.Style {
			styles[k] = v
		}
		*value = ast.PropertyValue{Style: styles}
	default:
		return fmt.Errorf("invalid property value")
	}
	return nil
}

// parseWidget converts a widget node to a WidgetNode
func (p *Parser) parseWidget(node *ast.WidgetNode) (*ast.WidgetNode, error) {
	if node == nil {
		return nil, nil
	}

	// Parse properties
	props := make(map[string]ast.PropertyValue)
	for name, value := range node.Properties {
		if err := p.parsePropertyValue(&value); err != nil {
			return nil, err
		}
		props[name] = value
	}

	// Parse children
	children := make([]*ast.WidgetNode, len(node.Children))
	for i, child := range node.Children {
		parsedChild, err := p.parseWidget(child)
		if err != nil {
			return nil, err
		}
		children[i] = parsedChild
	}

	return &ast.WidgetNode{
		Name:       node.Name,
		Properties: props,
		Children:   children,
	}, nil
}

// parseWidgetTree converts a widget tree to a WidgetTree
func (p *Parser) parseWidgetTree(tree *ast.WidgetTree) (*ast.WidgetTree, error) {
	if tree == nil {
		return nil, nil
	}

	root, err := p.parseWidget(tree.Root)
	if err != nil {
		return nil, err
	}

	return &ast.WidgetTree{
		Root: root,
	}, nil
}

// Helper function to create string pointers
func stringPtr(s string) *string {
	return &s
}
