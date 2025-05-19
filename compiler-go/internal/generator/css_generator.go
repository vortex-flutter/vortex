package generator

// CSSGenerator generates CSS styles for Flutter widgets
type CSSGenerator struct{}

// NewCSSGenerator creates a new CSS generator
func NewCSSGenerator() *CSSGenerator {
	return &CSSGenerator{}
}

// Generate creates CSS styles for the Flutter widgets
func (g *CSSGenerator) Generate() string {
	return `
/* Material Design Variables */
:root {
  --primary-color: #2196F3;
  --primary-light: #64B5F6;
  --primary-dark: #1976D2;
  --accent-color: #FF4081;
  --text-primary: rgba(0, 0, 0, 0.87);
  --text-secondary: rgba(0, 0, 0, 0.6);
  --text-disabled: rgba(0, 0, 0, 0.38);
  --divider-color: rgba(0, 0, 0, 0.12);
  --background-color: #FFFFFF;
  --surface-color: #FFFFFF;
  --error-color: #B00020;
}

/* Base Styles */
body {
  margin: 0;
  padding: 0;
  font-family: 'Roboto', sans-serif;
  color: var(--text-primary);
  background-color: var(--background-color);
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
}

/* Layout */
.material-app {
  min-height: 100vh;
  display: flex;
  flex-direction: column;
}

.scaffold {
  display: flex;
  flex-direction: column;
  min-height: 100vh;
}

.scaffold-body {
  flex: 1;
  padding: 16px;
  background-color: var(--background-color);
}

/* AppBar */
.app-bar {
  background-color: var(--primary-color);
  color: white;
  padding: 0 16px;
  height: 56px;
  display: flex;
  align-items: center;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
}

.app-bar-title {
  font-size: 20px;
  font-weight: 500;
  margin-right: 16px;
}

.app-bar-actions {
  margin-left: auto;
}

/* Text */
.text-base {
  font-size: 16px;
  line-height: 1.5;
  color: var(--text-primary);
}

/* Buttons */
.elevated-button {
  background-color: var(--primary-color);
  color: white;
  border: none;
  border-radius: 4px;
  padding: 8px 16px;
  font-size: 14px;
  font-weight: 500;
  text-transform: uppercase;
  cursor: pointer;
  transition: background-color 0.2s, box-shadow 0.2s;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
}

.elevated-button:hover {
  background-color: var(--primary-dark);
  box-shadow: 0 4px 8px rgba(0, 0, 0, 0.2);
}

.elevated-button:active {
  background-color: var(--primary-dark);
  box-shadow: 0 1px 2px rgba(0, 0, 0, 0.1);
}

/* Layout Components */
.flex {
  display: flex;
}

.row {
  flex-direction: row;
}

.column {
  flex-direction: column;
}

.items-center {
  align-items: center;
}

.justify-center {
  justify-content: center;
}

.flex-1 {
  flex: 1;
}

/* Container */
.container {
  padding: 16px;
  background-color: var(--surface-color);
  border-radius: 4px;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
}

/* SizedBox */
.sized-box {
  display: block;
}

/* Utility Classes */
.gap-4 {
  gap: 16px;
}

.p-4 {
  padding: 16px;
}

/* Responsive Design */
@media (max-width: 600px) {
  .app-bar {
    height: 48px;
  }

  .app-bar-title {
    font-size: 18px;
  }

  .container {
    padding: 12px;
  }

  .gap-4 {
    gap: 12px;
  }

  .p-4 {
    padding: 12px;
  }
}
`
}
