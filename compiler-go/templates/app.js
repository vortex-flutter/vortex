// Flutter to Web UI Framework

class FlutterUI {
  constructor() {
    this.state = {};
    this.elements = new Map();
    this.init();
  }

  init() {
    // Initialize the UI
    this.setupEventListeners();
    this.render();
  }

  setupEventListeners() {
    // Global event listeners
    document.addEventListener("click", (e) => this.handleClick(e));
    document.addEventListener("input", (e) => this.handleInput(e));
    document.addEventListener("change", (e) => this.handleChange(e));
  }

  // State management
  setState(newState) {
    this.state = { ...this.state, ...newState };
    this.render();
  }

  // Event handlers
  handleClick(e) {
    const target = e.target;
    const action = target.dataset.action;
    if (action) {
      this[action]?.(e);
    }
  }

  handleInput(e) {
    const target = e.target;
    const key = target.dataset.state;
    if (key) {
      this.setState({ [key]: target.value });
    }
  }

  handleChange(e) {
    const target = e.target;
    const key = target.dataset.state;
    if (key) {
      this.setState({ [key]: target.checked });
    }
  }

  // UI Components
  createElement(tag, props = {}, children = []) {
    const element = document.createElement(tag);

    // Set attributes
    Object.entries(props).forEach(([key, value]) => {
      if (key === "className") {
        element.className = value;
      } else if (key === "style" && typeof value === "object") {
        Object.assign(element.style, value);
      } else if (key.startsWith("on")) {
        const eventName = key.toLowerCase().slice(2);
        element.addEventListener(eventName, value);
      } else if (key === "dataState") {
        element.dataset.state = value;
      } else if (key === "dataAction") {
        element.dataset.action = value;
      } else {
        element.setAttribute(key, value);
      }
    });

    // Add children
    if (typeof children === "string") {
      element.textContent = children;
    } else {
      children.forEach((child) => {
        if (child instanceof Node) {
          element.appendChild(child);
        } else if (typeof child === "string") {
          element.appendChild(document.createTextNode(child));
        }
      });
    }

    return element;
  }

  // Flutter-like components
  Text(text, props = {}) {
    return this.createElement(
      "span",
      {
        className: "text-base " + (props.className || ""),
        ...props,
      },
      text
    );
  }

  Container(props = {}, children = []) {
    return this.createElement(
      "div",
      {
        className: "p-4 " + (props.className || ""),
        ...props,
      },
      children
    );
  }

  Row(props = {}, children = []) {
    return this.createElement(
      "div",
      {
        className: "flex row " + (props.className || ""),
        ...props,
      },
      children
    );
  }

  Column(props = {}, children = []) {
    return this.createElement(
      "div",
      {
        className: "flex column " + (props.className || ""),
        ...props,
      },
      children
    );
  }

  Button(props = {}, children = []) {
    return this.createElement(
      "button",
      {
        className: "button " + (props.className || ""),
        ...props,
      },
      children
    );
  }

  TextField(props = {}) {
    return this.createElement("input", {
      type: "text",
      className: "text-field " + (props.className || ""),
      ...props,
    });
  }

  Card(props = {}, children = []) {
    return this.createElement(
      "div",
      {
        className: "card " + (props.className || ""),
        ...props,
      },
      children
    );
  }

  // Navigation
  navigate(path) {
    window.history.pushState({}, "", path);
    this.render();
  }

  // Render method
  render() {
    const app = document.querySelector(".app");
    if (!app) return;

    // Clear existing content
    app.innerHTML = "";

    // Render the UI based on current state
    const content = this.buildUI();
    app.appendChild(content);
  }

  // This method should be overridden by the app
  buildUI() {
    // Default UI
    return this.Column({}, [
      this.Text("Welcome to Flutter Web!"),
      this.Button(
        {
          dataAction: "incrementCounter",
          className: "primary",
        },
        "Click me"
      ),
    ]);
  }

  // Example actions
  incrementCounter() {
    this.setState({
      counter: (this.state.counter || 0) + 1,
    });
  }
}

// Initialize the UI when the DOM is loaded
document.addEventListener("DOMContentLoaded", () => {
  window.app = new FlutterUI();
});
