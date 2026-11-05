@tool
extends EditorPlugin

const FightLabDock: GDScript = preload("uid://bvhpw0lxa5wqh")  # fight_lab_dock.gd
## Under this name in [Engine]'s meta, so other editor tools (the adventure editor) can open a scenario in the lab ([method open_scenario])
const META: StringName = &"fight_lab"

var _dock: Control

func _enter_tree() -> void:
	_dock = FightLabDock.new()
	add_control_to_bottom_panel(_dock, "Fight Lab")
	Engine.set_meta(META, self)

func _exit_tree() -> void:
	if Engine.get_meta(META, null) == self: Engine.remove_meta(META)
	remove_control_from_bottom_panel(_dock)
	_dock.queue_free()

## Shows the lab and runs [param scenario] there
func open_scenario(scenario: FightLabScenario) -> void:
	make_bottom_panel_item_visible(_dock)
	_dock.call(&"open_scenario", scenario)
