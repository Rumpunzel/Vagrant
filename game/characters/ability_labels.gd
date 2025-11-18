@tool
class_name AbilityLabels
extends VBoxContainer

@export_group("Configuration")
@export var _ability_label: PackedScene

func update_abilities(origins: Array[Origin]) -> void:
	_clear()
	for origin: Origin in origins:
		var ability_label: AbilityLabel = _ability_label.instantiate()
		ability_label.origin = origin
		add_child(ability_label)

func _clear() -> void:
	while get_child_count() > 0:
		var child: Node = get_child(0)
		remove_child(child)
		child.queue_free()
