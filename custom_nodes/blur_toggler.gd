class_name BlurToggler
extends Node

@export var trigger_node: CanvasItem :
	set(new_trigger_node):
		trigger_node = new_trigger_node
		if trigger_node: _on_visibility_changed()
		trigger_node.visibility_changed.connect(_on_visibility_changed)

func _ready() -> void:
	if not trigger_node: trigger_node = get_parent()
	assert(trigger_node)

func _on_visibility_changed() -> void:
	assert(trigger_node)
	if trigger_node.visible: BlurLayer.fade_in()
	else: BlurLayer.fade_out()
