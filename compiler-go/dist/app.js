
// Flutter to Web UI Framework
class FlutterUI {
  constructor() {
    this.state = {};
    this.elements = new Map();
    this.setupStyles();
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

    // Add Material Design styles
    const style = document.createElement('style');
    style.textContent = `
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
        border-radius: 50%;
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
    `;
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
}


class MyHomePage extends FlutterUI {
  constructor(props = {}, children = []) {
    super();
    this.props = props;
    this.children = children;
    this.state = {};
  }

  buildUI() {
    // The actual widget tree will be generated by the compiler
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


// Generated from Flutter
class App extends FlutterUI {
  constructor() {
    super();
    this.isRootApp = true;
  }
  buildUI() {
    return this.MaterialApp({title: 'Flutter Demo', theme: {primaryswatch: 'Colors.blue'}, home: new MyHomePage({title: 'Flutter Demo Home Page'}, [])}, []);
  }
}

// Initialize the app
document.addEventListener('DOMContentLoaded', () => {
  window.app = new App();
  window.app.init();
});
