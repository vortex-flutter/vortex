package ast

// WidgetTree represents the root of a Flutter widget tree
type WidgetTree struct {
	Root *WidgetNode
}

// WidgetNode represents a Flutter widget in the tree
type WidgetNode struct {
	Name       string
	Properties map[string]PropertyValue
	Children   []*WidgetNode
}

// PropertyValue represents a value that can be assigned to a widget property
type PropertyValue interface {
	IsPropertyValue()
}

// StringValue represents a string property value
type StringValue string

func (StringValue) IsPropertyValue() {}

// NumberValue represents a numeric property value
type NumberValue float64

func (NumberValue) IsPropertyValue() {}

// BooleanValue represents a boolean property value
type BooleanValue bool

func (BooleanValue) IsPropertyValue() {}

// WidgetValue represents a child widget property value
type WidgetValue struct {
	Widget *WidgetNode
}

func (WidgetValue) IsPropertyValue() {}

// ListValue represents a list of property values
type ListValue struct {
	Values []PropertyValue
}

func (ListValue) IsPropertyValue() {}
