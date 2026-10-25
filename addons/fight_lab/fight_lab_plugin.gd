@tool
extends EditorPlugin

const FightLabDock: GDScript = preload("uid://bvhpw0lxa5wqh")  # fight_lab_dock.gd

var _dock: Control

func _enter_tree() -> void:
	_dock = FightLabDock.new()
	add_control_to_bottom_panel(_dock, "Fight Lab")

func _exit_tree() -> void:
	remove_control_from_bottom_panel(_dock)
	_dock.queue_free()
