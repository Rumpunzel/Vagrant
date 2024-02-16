@tool
class_name VerticalGridContainer
extends GridContainer

func add_children_vertically(children: Array[Control]) -> void:
	for index: int in children.size():
		@warning_ignore("integer_division")
		var column_index := (index % columns) * (children.size() / columns)
		@warning_ignore("integer_division")
		var row_index := index / columns
		var child: Control = children[column_index + row_index]
		add_child(child)
