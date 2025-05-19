package generator

import (
	"fmt"
	"strings"
	"text/template"

	"compiler-go/internal/ast"
	"compiler-go/internal/config"
)

type JSGenerator struct {
	templates *template.Template
	sourceDir string
}

func NewJSGenerator() *JSGenerator {
	return &JSGenerator{
		templates: template.New("js"),
	}
}

func (g *JSGenerator) SetSourceDir(dir string) {
	g.sourceDir = dir
}

// Generate converts Flutter widgets to JavaScript code
func (g *JSGenerator) Generate(widgetTree *ast.WidgetTree) (string, error) {
	// Load config
	cfg, err := config.LoadConfig(g.sourceDir)
	if err != nil {
		return "", fmt.Errorf("error loading config: %v", err)
	}

	// Generate imports
	imports := g.generateImports(cfg)

	// Find all custom widgets
	customWidgets := make(map[string]bool)
	g.findCustomWidgets(widgetTree.Root, customWidgets)

	// Generate custom widget class definitions
	var customWidgetDefs strings.Builder
	for widgetName := range customWidgets {
		customWidgetDefs.WriteString(fmt.Sprintf(`
class %s extends FlutterUI {
  constructor(props = {}, children = []) {
    super();
    this.props = props;
    this.children = children;
    this.state = {};
  }

  buildUI() {
    return this.Scaffold({
      appBar: this.AppBar({
        title: this.Text(this.props.title || '')
      }),
      body: this.Center({
        child: this.Column({
          mainAxisAlignment: 'center',
          children: [
            this.Text('Hello, World!', {
              style: {
                fontSize: '24px',
                fontWeight: 'bold'
              }
            }),
            this.SizedBox({ height: 20 }),
            this.ElevatedButton({
              onPressed: () => console.log('Button pressed!')
            }, [
              this.Text('Click Me')
            ])
          ]
        })
      }),
      floatingActionButton: this.FloatingActionButton({
        onPressed: () => console.log('FAB pressed!')
      }, [
        this.Icon({ icon: 'add' })
      ])
    });
  }
}
`, widgetName))
	}

	// Generate the widget code
	widgetCode := g.generateWidgetCode(widgetTree.Root)

	// Combine everything
	code := fmt.Sprintf(`%s

%s

// Flutter to Web UI Framework
class FlutterUI {
  constructor() {
    this.state = {};
    this.elements = new Map();
    this.setupStyles();
    this.setupRouter();
  }

  setupRouter() {
    // Initialize router using Vortex's routing system
    this.router = {
      currentPath: window.location.pathname,
      navigate: (path) => {
        window.history.pushState({}, '', path);
        this.router.currentPath = path;
        this.render();
      }
    };

    // Handle browser back/forward
    window.addEventListener('popstate', () => {
      this.router.currentPath = window.location.pathname;
      this.render();
    });
  }

  setupStyles() {
    // Add Material Icons font
    const materialIcons = document.createElement('link');
    materialIcons.href = 'https://fonts.googleapis.com/icon?family=Material+Icons';
    materialIcons.rel = 'stylesheet';
    document.head.appendChild(materialIcons);

    // Add Roboto font
    const roboto = document.createElement('link');
    roboto.href = 'https://fonts.googleapis.com/css2?family=Roboto:wght@300;400;500;700&display=swap';
    roboto.rel = 'stylesheet';
    document.head.appendChild(roboto);

    // Add FlutterWind if enabled
    if (%v) {
      const flutterwind = document.createElement('link');
      flutterwind.href = 'https://cdn.jsdelivr.net/npm/flutterwind@latest/dist/flutterwind.min.css';
      flutterwind.rel = 'stylesheet';
      document.head.appendChild(flutterwind);
    }

    // Add Material Design styles
    const style = document.createElement('style');
    style.textContent = `+"`"+`
      :root {
        --primary-color: #2196F3;
        --primary-dark: #1976D2;
        --primary-light: #BBDEFB;
        --accent-color: #FF4081;
        --text-primary: rgba(0, 0, 0, 0.87);
        --text-secondary: rgba(0, 0, 0, 0.6);
        --text-disabled: rgba(0, 0, 0, 0.38);
        --divider-color: rgba(0, 0, 0, 0.12);
        --elevation-1: 0 2px 1px -1px rgba(0,0,0,0.2), 0 1px 1px 0 rgba(0,0,0,0.14), 0 1px 3px 0 rgba(0,0,0,0.12);
        --elevation-2: 0 3px 1px -2px rgba(0,0,0,0.2), 0 2px 2px 0 rgba(0,0,0,0.14), 0 1px 5px 0 rgba(0,0,0,0.12);
        --elevation-4: 0 2px 4px -1px rgba(0,0,0,0.2), 0 4px 5px 0 rgba(0,0,0,0.14), 0 1px 10px 0 rgba(0,0,0,0.12);
        --elevation-8: 0 5px 5px -3px rgba(0,0,0,0.2), 0 8px 10px 1px rgba(0,0,0,0.14), 0 3px 14px 2px rgba(0,0,0,0.12);
      }

      body {
        font-family: 'Roboto', sans-serif;
        margin: 0;
        padding: 0;
        color: var(--text-primary);
        background-color: #f5f5f5;
      }

      .material-app {
        min-height: 100vh;
        background-color: white;
      }

      .app-bar {
        background-color: var(--primary-color);
        color: white;
        height: 64px;
        display: flex;
        align-items: center;
        padding: 0 16px;
        box-shadow: var(--elevation-4);
        position: relative;
        z-index: 100;
      }

      .app-bar-title {
        font-size: 20px;
        font-weight: 500;
        letter-spacing: 0.15px;
      }

      .elevated-button {
        background-color: var(--primary-color);
        color: white;
        border: none;
        border-radius: 4px;
        padding: 8px 16px;
        font-size: 14px;
        font-weight: 500;
        text-transform: uppercase;
        letter-spacing: 0.75px;
        box-shadow: var(--elevation-2);
        cursor: pointer;
        transition: all 0.2s ease;
      }

      .elevated-button:hover {
        box-shadow: var(--elevation-4);
        background-color: var(--primary-dark);
      }

      .elevated-button:active {
        box-shadow: var(--elevation-1);
      }

      .floating-action-button {
        position: fixed;
        bottom: 16px;
        right: 16px;
        width: 56px;
        height: 56px;
        border-radius: 50%%;
        background-color: var(--primary-color);
        color: white;
        border: none;
        box-shadow: var(--elevation-6);
        display: flex;
        align-items: center;
        justify-content: center;
        cursor: pointer;
        transition: all 0.2s ease;
        z-index: 1000;
      }

      .floating-action-button:hover {
        box-shadow: var(--elevation-8);
        background-color: var(--primary-dark);
      }

      .floating-action-button:active {
        box-shadow: var(--elevation-4);
      }

      .material-icons {
        font-family: 'Material Icons';
        font-weight: normal;
        font-style: normal;
        font-size: 24px;
        line-height: 1;
        letter-spacing: normal;
        text-transform: none;
        display: inline-block;
        white-space: nowrap;
        word-wrap: normal;
        direction: ltr;
      }

      .scaffold {
        display: flex;
        flex-direction: column;
        min-height: 100vh;
        background-color: white;
      }

      .scaffold-body {
        flex: 1;
        position: relative;
        padding: 16px;
      }

      .text-base {
        font-size: 16px;
        line-height: 1.5;
        letter-spacing: 0.15px;
      }

      .sized-box {
        display: block;
      }
    `+"`"+`;
    document.head.appendChild(style);
  }

  init() {
    this.setupEventListeners();
    this.render();
  }

  setupEventListeners() {
    document.addEventListener('click', (e) => this.handleClick(e));
    document.addEventListener('input', (e) => this.handleInput(e));
  }

  setState(newState) {
    this.state = { ...this.state, ...newState };
    if (this.isRootApp) {
      this.render();
    } else if (this.parentElement) {
      const newElement = this.buildUI();
      this.parentElement.replaceChild(newElement, this.renderedElement);
      this.renderedElement = newElement;
    }
  }

  handleClick(e) {
    const target = e.target.closest('[data-action]');
    if (target) {
      const action = target.dataset.action;
      const actionHandler = this[action] || window.app[action];
      if (typeof actionHandler === 'function') {
        actionHandler.call(this.isRootApp ? this : window.app, e);
      }
    }
  }

  handleInput(e) {
    const target = e.target.closest('[data-state]');
    if (target) {
      const key = target.dataset.state;
      this.setState({ [key]: target.value });
    }
  }

  render() {
    const appRootElement = document.querySelector('.app');
    if (!appRootElement) {
      console.error('.app root element not found');
      return;
    }
    appRootElement.innerHTML = '';
    const content = this.buildUI();
    if (content) {
      appRootElement.appendChild(content);
    }
  }

  createElement(tag, props = {}, children = []) {
    const element = document.createElement(tag);
    let eventListeners = {};

    Object.entries(props).forEach(([key, value]) => {
      if (key === 'className') {
        element.className = value;
      } else if (key === 'style' && typeof value === 'object') {
        Object.assign(element.style, value);
      } else if (key.startsWith('on') && typeof value === 'function') {
        const eventName = key.toLowerCase().substring(2);
        eventListeners[eventName] = value;
      } else if (key === 'dataAction') {
        element.dataset.action = value;
      } else if (key === 'dataState') {
        element.dataset.state = value;
      } else if (key !== 'key' && key !== 'ref') {
        if (typeof value !== 'object' && typeof value !== 'function') {
          element.setAttribute(key, value);
        }
      }
    });

    const childNodes = Array.isArray(children) ? children : [children];
    childNodes.forEach(child => {
      if (child instanceof Node) {
        element.appendChild(child);
      } else if (typeof child === 'string' || typeof child === 'number') {
        element.appendChild(document.createTextNode(child.toString()));
      }
    });

    Object.entries(eventListeners).forEach(([eventName, handler]) => {
      element.addEventListener(eventName, handler);
    });

    return element;
  }

  Text(text, props = {}) {
    const actualText = (props && props.text !== undefined) ? props.text : text;
    delete props.text;
    return this.createElement('span', {
      className: 'text-base ' + (props.className || ''),
      style: {
        color: 'var(--text-primary)',
        ...props.style
      },
      ...props
    }, actualText !== undefined ? String(actualText) : '');
  }

  Center(props = {}, children = []) {
    const child = props.child;
    delete props.child;
    return this.createElement('div', {
      className: 'flex items-center justify-center ' + (props.className || ''),
      ...props
    }, child ? [child] : children);
  }

  SizedBox(props = {}) {
    return this.createElement('div', {
      className: 'sized-box ' + (props.className || ''),
      style: {
        width: props.width ? props.width + 'px' : 'auto',
        height: props.height ? props.height + 'px' : 'auto',
        ...props.style
      }
    });
  }

  ElevatedButton(props = {}, children = []) {
    const onPressed = props.onPressed;
    delete props.onPressed;
    
    return this.createElement('button', {
      className: 'elevated-button ' + (props.className || ''),
      dataAction: onPressed ? 'onPressed' : undefined,
      onClick: onPressed,
      style: {
        ...props.style
      },
      ...props
    }, children);
  }

  Container(props = {}, children = []) {
    return this.createElement('div', {
      className: 'container ' + (props.className || ''),
      ...props
    }, children);
  }

  Row(props = {}, children = []) {
    return this.createElement('div', {
      className: 'flex row ' + (props.className || ''),
      ...props
    }, children);
  }

  Column(props = {}, children = []) {
    const mainAxisAlignment = props.mainAxisAlignment;
    delete props.mainAxisAlignment;
    
    let className = 'flex column ';
    if (mainAxisAlignment) {
      className += 'justify-' + mainAxisAlignment + ' ';
    }
    className += (props.className || '');
    
    // Use children from props if available, otherwise use the children parameter
    const actualChildren = props.children || children;
    delete props.children;
    
    return this.createElement('div', {
      className: className,
      ...props
    }, actualChildren);
  }

  MaterialApp(props = {}, children = []) {
    const homeWidget = props.home;
    delete props.home;

    if (props.themeData) {
      const theme = props.themeData;
      if (theme.primarySwatch) {
        document.documentElement.style.setProperty('--primary-color', theme.primarySwatch);
      }
      delete props.themeData;
    }

    let homeElement = null;
    if (homeWidget) {
      if (homeWidget && typeof homeWidget.buildUI === 'function') {
        homeElement = homeWidget.buildUI();
        homeWidget.parentElement = this.createElement('div');
        homeWidget.renderedElement = homeElement;
      } else if (homeWidget instanceof Node) {
        homeElement = homeWidget;
      }
    }
    const actualChildren = homeElement ? [homeElement] : (Array.isArray(children) ? children : (children ? [children] : []));
    
    return this.createElement('div', {
      className: 'material-app ' + (props.className || ''),
      ...props
    }, actualChildren);
  }

  Scaffold(props = {}, children = []) {
    const appBarWidget = props.appBar;
    const bodyWidget = props.body;
    const floatingActionButtonWidget = props.floatingActionButton;
    delete props.appBar;
    delete props.body;
    delete props.floatingActionButton;

    let appBarElement = null;
    if (appBarWidget) {
      if (appBarWidget && typeof appBarWidget.buildUI === 'function') {
        appBarElement = appBarWidget.buildUI();
        appBarWidget.parentElement = this.createElement('header');
        appBarWidget.renderedElement = appBarElement;
      } else if (appBarWidget instanceof Node) {
        appBarElement = appBarWidget;
      }
    }

    let bodyContentNodes = [];
    if (bodyWidget) {
      if (bodyWidget && typeof bodyWidget.buildUI === 'function') {
        const bodyElement = bodyWidget.buildUI();
        bodyContentNodes = [bodyElement];
        bodyWidget.parentElement = this.createElement('main');
        bodyWidget.renderedElement = bodyElement;
      } else if (Array.isArray(bodyWidget)) {
        bodyContentNodes = bodyWidget.map(item => item && typeof item.buildUI === 'function' ? item.buildUI() : (item instanceof Node ? item : null)).filter(n => n);
      } else if (bodyWidget instanceof Node) {
        bodyContentNodes = [bodyWidget];
      }
    } else if (children) {
      bodyContentNodes = Array.isArray(children) ? children : [children];
      bodyContentNodes = bodyContentNodes.map(item => item && typeof item.buildUI === 'function' ? item.buildUI() : (item instanceof Node ? item : null)).filter(n => n);
    }

    let fabElement = null;
    if (floatingActionButtonWidget) {
      if (floatingActionButtonWidget && typeof floatingActionButtonWidget.buildUI === 'function') {
        fabElement = floatingActionButtonWidget.buildUI();
      } else if (floatingActionButtonWidget instanceof Node) {
        fabElement = floatingActionButtonWidget;
      }
    }

    const scaffoldDiv = this.createElement('div', {
      className: 'scaffold ' + (props.className || ''),
      style: {
        ...props.style
      },
      ...props
    });

    if (appBarElement) {
      scaffoldDiv.appendChild(appBarElement);
    }
    
    const mainElement = this.createElement('main', { 
      className: 'scaffold-body',
      style: {
        ...props.style
      }
    });
    bodyContentNodes.forEach(childNode => mainElement.appendChild(childNode));
    scaffoldDiv.appendChild(mainElement);

    if (fabElement) {
      scaffoldDiv.appendChild(fabElement);
    }

    return scaffoldDiv;
  }

  AppBar(props = {}, children = []) {
    const titleWidget = props.title;
    delete props.title;

    let titleElement = null;
    if (titleWidget) {
      if (titleWidget && typeof titleWidget.buildUI === 'function') {
        titleElement = titleWidget.buildUI();
      } else if (titleWidget instanceof Node) {
        titleElement = titleWidget;
      } else if (typeof titleWidget === 'string' || typeof titleWidget === 'number') {
        titleElement = this.Text(String(titleWidget));
      }
    }
    
    const actionElements = (Array.isArray(children) ? children : (children ? [children] : [])).map(
      item => item && typeof item.buildUI === 'function' ? item.buildUI() : (item instanceof Node ? item : null)
    ).filter(n => n);

    const headerElement = this.createElement('header', {
      className: 'app-bar ' + (props.className || ''),
      ...props
    });

    if (titleElement) {
      const titleContainer = this.createElement('div', { className: 'app-bar-title flex-1' });
      titleContainer.appendChild(titleElement);
      headerElement.appendChild(titleContainer);
    }

    if (actionElements.length > 0) {
      const actionsContainer = this.createElement('div', { className: 'app-bar-actions flex row items-center' });
      actionElements.forEach(action => actionsContainer.appendChild(action));
      headerElement.appendChild(actionsContainer);
    }
    return headerElement;
  }

  FloatingActionButton(props = {}, children = []) {
    const onPressed = props.onPressed;
    delete props.onPressed;
    
    return this.createElement('button', {
      className: 'floating-action-button ' + (props.className || ''),
      dataAction: onPressed ? 'onPressed' : undefined,
      onClick: onPressed,
      style: {
        ...props.style
      },
      ...props
    }, children);
  }

  Icon(props = {}) {
    const iconName = props.icon || 'add';
    delete props.icon;
    
    return this.createElement('span', {
      className: 'material-icons ' + (props.className || ''),
      style: {
        color: 'white',
        ...props.style
      },
      ...props
    }, iconName);
  }

  // Add navigation methods
  navigate(path) {
    this.router.navigate(path);
  }

  Link(props = {}, children = []) {
    const href = props.href;
    delete props.href;

    return this.createElement('a', {
      ...props,
      href: href,
      onClick: (e) => {
        e.preventDefault();
        this.navigate(href);
      }
    }, children);
  }
}

%s

// Generated from Flutter
class App extends FlutterUI {
  constructor() {
    super();
    this.isRootApp = true;
  }
  buildUI() {
    return %s;
  }
}

// Initialize the app
document.addEventListener('DOMContentLoaded', () => {
  window.app = new App();
  window.app.init();
});
`, imports, customWidgetDefs.String(), cfg.Compiler.UseFlutterWind, widgetCode)

	return code, nil
}

func (g *JSGenerator) generateImports(cfg *config.VortexConfig) string {
	imports := []string{
		"import { createElement } from 'vortex';",
	}

	if cfg.Compiler.UseFlutterWind {
		imports = append(imports, "import { tw } from 'flutterwind';")
	}

	return strings.Join(imports, "\n")
}

// findCustomWidgets finds all custom widget classes in the widget tree
func (g *JSGenerator) findCustomWidgets(node *ast.WidgetNode, customWidgets map[string]bool) {
	if node == nil {
		return
	}

	// Check if this is a custom widget
	if strings.HasPrefix(node.Name, "My") || strings.HasPrefix(node.Name, "Custom") {
		customWidgets[node.Name] = true
	}

	// Check children
	for _, child := range node.Children {
		g.findCustomWidgets(child, customWidgets)
	}

	// Check widget properties
	for _, value := range node.Properties {
		if value.Widget != nil {
			g.findCustomWidgets(value.Widget, customWidgets)
		}
	}
}

// generateWidgetCode converts a widget node to JavaScript code
func (g *JSGenerator) generateWidgetCode(node *ast.WidgetNode) string {
	if node == nil {
		return "null"
	}

	// Convert widget name to camelCase for JavaScript
	jsName := g.toCamelCase(node.Name)

	// Generate props
	props := g.generateProps(node.Properties)

	// Generate children
	children := g.generateChildren(node.Children)

	// For custom widget classes, create a new instance
	if strings.HasPrefix(node.Name, "My") || strings.HasPrefix(node.Name, "Custom") {
		return fmt.Sprintf("new %s(%s, %s)", jsName, props, children)
	}

	// Special handling for certain widgets
	switch node.Name {
	case "MaterialApp":
		return fmt.Sprintf("this.MaterialApp(%s, %s)", props, children)
	case "Scaffold":
		// Special handling for Scaffold to properly handle floatingActionButton
		floatingActionButton := ""
		if value, ok := node.Properties["floatingActionButton"]; ok && value.Widget != nil {
			floatingActionButton = g.generateWidgetCode(value.Widget)
		}
		propsWithoutFAB := g.generatePropsWithoutFAB(node.Properties)
		return fmt.Sprintf("this.Scaffold({...%s, floatingActionButton: %s}, %s)",
			propsWithoutFAB, floatingActionButton, children)
	case "AppBar":
		return fmt.Sprintf("this.AppBar(%s, %s)", props, children)
	case "Center":
		return fmt.Sprintf("this.Center(%s, %s)", props, children)
	case "Column":
		// Special handling for Column to properly handle mainAxisAlignment and children
		mainAxisAlignment := ""
		if value, ok := node.Properties["mainAxisAlignment"]; ok && value.String != nil {
			mainAxisAlignment = *value.String
		}
		propsWithoutMainAxis := g.generatePropsWithoutMainAxis(node.Properties)
		return fmt.Sprintf("this.Column({...%s, mainAxisAlignment: '%s', children: %s})",
			propsWithoutMainAxis, mainAxisAlignment, children)
	case "Text":
		return fmt.Sprintf("this.Text(%s, %s)", props, children)
	case "ElevatedButton":
		return fmt.Sprintf("this.ElevatedButton(%s, %s)", props, children)
	case "SizedBox":
		return fmt.Sprintf("this.SizedBox(%s)", props)
	case "FloatingActionButton":
		return fmt.Sprintf("this.FloatingActionButton(%s, %s)", props, children)
	case "Icon":
		iconName := ""
		if value, ok := node.Properties["icon"]; ok && value.String != nil {
			iconName = *value.String
		}
		propsWithoutIcon := g.generatePropsWithoutIcon(node.Properties)
		return fmt.Sprintf("this.Icon({...%s, icon: '%s'})", propsWithoutIcon, iconName)
	default:
		return fmt.Sprintf("this.%s(%s, %s)", jsName, props, children)
	}
}

// generateProps converts widget properties to JavaScript object
func (g *JSGenerator) generateProps(props map[string]ast.PropertyValue) string {
	if len(props) == 0 {
		return "{}"
	}

	var propStrings []string
	for name, value := range props {
		if name == "children" {
			continue // skip children property, handled as children array
		}
		jsName := g.toCamelCase(name)
		jsValue := g.generatePropertyValue(value)
		propStrings = append(propStrings, fmt.Sprintf("%s: %s", jsName, jsValue))
	}

	return fmt.Sprintf("{%s}", strings.Join(propStrings, ", "))
}

// generatePropertyValue converts a property value to JavaScript
func (g *JSGenerator) generatePropertyValue(value ast.PropertyValue) string {
	switch {
	case value.String != nil:
		return fmt.Sprintf("'%s'", *value.String)
	case value.Number != nil:
		return fmt.Sprintf("%v", *value.Number)
	case value.Boolean != nil:
		return fmt.Sprintf("%v", *value.Boolean)
	case value.Widget != nil:
		if value.Widget.Name == "ThemeData" {
			props := g.generateProps(value.Widget.Properties)
			return props
		}
		return g.generateWidgetCode(value.Widget)
	case value.List != nil:
		return g.generateList(value.List)
	case value.Style != nil:
		var styleStrings []string
		for k, v := range value.Style {
			// Convert camelCase to kebab-case for CSS properties
			jsName := g.toCamelCase(k)
			styleStrings = append(styleStrings, fmt.Sprintf("%s: '%s'", jsName, v))
		}
		return fmt.Sprintf("{style: {%s}}", strings.Join(styleStrings, ", "))
	default:
		return "null"
	}
}

// generateList converts a list of values to JavaScript array
func (g *JSGenerator) generateList(items []ast.PropertyValue) string {
	if len(items) == 0 {
		return "[]"
	}

	var itemStrings []string
	for _, item := range items {
		itemStrings = append(itemStrings, g.generatePropertyValue(item))
	}

	return fmt.Sprintf("[%s]", strings.Join(itemStrings, ", "))
}

// generateChildren converts child widgets to JavaScript array
func (g *JSGenerator) generateChildren(children []*ast.WidgetNode) string {
	if len(children) == 0 {
		return "[]"
	}

	var childStrings []string
	for _, child := range children {
		childStrings = append(childStrings, g.generateWidgetCode(child))
	}

	return fmt.Sprintf("[%s]", strings.Join(childStrings, ", "))
}

// toCamelCase converts a string to camelCase
func (g *JSGenerator) toCamelCase(s string) string {
	// Handle special cases
	switch s {
	case "MaterialApp":
		return "MaterialApp"
	case "Scaffold":
		return "Scaffold"
	case "AppBar":
		return "AppBar"
	case "Text":
		return "Text"
	case "Container":
		return "Container"
	case "Row":
		return "Row"
	case "Column":
		return "Column"
	case "Button":
		return "Button"
	case "TextField":
		return "TextField"
	case "Card":
		return "Card"
	case "ThemeData":
		return "themeData"
	case "mainAxisAlignment":
		return "mainAxisAlignment"
	case "fontSize":
		return "fontSize"
	case "fontWeight":
		return "fontWeight"
	default:
		// For custom widget classes, keep the original name
		if strings.HasPrefix(s, "My") || strings.HasPrefix(s, "Custom") {
			return s
		}
		// Convert to camelCase for other cases
		parts := strings.Split(s, "_")
		for i, part := range parts {
			if i == 0 {
				parts[i] = strings.ToLower(part)
			} else {
				parts[i] = strings.Title(part)
			}
		}
		return strings.Join(parts, "")
	}
}

// generatePropsWithoutMainAxis generates props without the mainAxisAlignment property
func (g *JSGenerator) generatePropsWithoutMainAxis(props map[string]ast.PropertyValue) string {
	if len(props) == 0 {
		return "{}"
	}

	var propStrings []string
	for name, value := range props {
		if name == "children" || name == "mainAxisAlignment" {
			continue
		}
		jsName := g.toCamelCase(name)
		jsValue := g.generatePropertyValue(value)
		propStrings = append(propStrings, fmt.Sprintf("%s: %s", jsName, jsValue))
	}

	return fmt.Sprintf("{%s}", strings.Join(propStrings, ", "))
}

// generatePropsWithoutFAB generates props without the floatingActionButton property
func (g *JSGenerator) generatePropsWithoutFAB(props map[string]ast.PropertyValue) string {
	if len(props) == 0 {
		return "{}"
	}

	var propStrings []string
	for name, value := range props {
		if name == "floatingActionButton" {
			continue
		}
		jsName := g.toCamelCase(name)
		jsValue := g.generatePropertyValue(value)
		propStrings = append(propStrings, fmt.Sprintf("%s: %s", jsName, jsValue))
	}

	return fmt.Sprintf("{%s}", strings.Join(propStrings, ", "))
}

// generatePropsWithoutIcon generates props without the icon property
func (g *JSGenerator) generatePropsWithoutIcon(props map[string]ast.PropertyValue) string {
	if len(props) == 0 {
		return "{}"
	}

	var propStrings []string
	for name, value := range props {
		if name == "icon" {
			continue
		}
		jsName := g.toCamelCase(name)
		jsValue := g.generatePropertyValue(value)
		propStrings = append(propStrings, fmt.Sprintf("%s: %s", jsName, jsValue))
	}

	return fmt.Sprintf("{%s}", strings.Join(propStrings, ", "))
}
