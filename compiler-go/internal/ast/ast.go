package ast

// WidgetTree represents the root of a Flutter widget tree
type WidgetTree struct {
	Root *WidgetNode
}

// WidgetNode represents a Flutter widget
type WidgetNode struct {
	Name       string
	Properties map[string]PropertyValue
	Children   []*WidgetNode
}

// PropertyValue represents a value that can be assigned to a widget property
type PropertyValue struct {
	String  *string
	Number  *float64
	Boolean *bool
	Widget  *WidgetNode
	List    []PropertyValue
	Style   map[string]string
}

// StringValue represents a string property value
type StringValue string

// NumberValue represents a number property value
type NumberValue float64

// BooleanValue represents a boolean property value
type BooleanValue bool

// WidgetValue represents a widget property value
type WidgetValue struct {
	Widget *WidgetNode
}

// ListValue represents a list of property values
type ListValue struct {
	Items []PropertyValue
}

// StyleValue represents a style property value
type StyleValue struct {
	Styles map[string]string
}

func (StringValue) isPropertyValue() {}

func (NumberValue) isPropertyValue() {}

func (BooleanValue) isPropertyValue() {}

func (WidgetValue) isPropertyValue() {}

func (ListValue) isPropertyValue() {}

func (StyleValue) isPropertyValue() {}
