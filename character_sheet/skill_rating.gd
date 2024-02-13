@tool
extends SpinBox

@export var skills: Array[NodePath]

func _process(_delta: float) -> void:
	var new_value := 0
	for skill in skills:
		var spin_box = get_node(skill) as SpinBox
		if spin_box.value > 0:
			new_value += 1
	value = new_value
