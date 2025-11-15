@tool
class_name FancyHoverButton
extends FancyButton

@export var fade_behavior: HoverFade.Behavior :
	set(new_fade_behavior): _hover_fade.fade_behavior = new_fade_behavior
	get: return _hover_fade.fade_behavior
@export var fade_in_time: float :
	set(new_fade_in_time): _hover_fade.fade_in_time = new_fade_in_time
	get: return _hover_fade.fade_in_time
@export var fade_in_delay: float :
	set(new_fade_in_delay): _hover_fade.fade_in_delay = new_fade_in_delay
	get: return _hover_fade.fade_in_delay
@export var fade_out_time: float :
	set(new_fade_out_time): _hover_fade.fade_out_time = new_fade_out_time
	get: return _hover_fade.fade_out_time
@export var fade_out_delay: float :
	set(new_fade_out_delay): _hover_fade.fade_out_delay = new_fade_out_delay
	get: return _hover_fade.fade_out_delay

@export_group("Neighbors")
@export var hover_neighbors: Array[FancyHoverButton] :
	set(new_hover_neighbors):
		hover_neighbors = new_hover_neighbors
		_hover_fade.hover_neighbors.assign(hover_neighbors.map(func(button: FancyHoverButton) -> HoverFade: return button._hover_fade))
@export var neighbor_hover_modulate: Color :
	set(new_neighbor_hover_modulate): _hover_fade.neighbor_hover_modulate = new_neighbor_hover_modulate
	get: return _hover_fade.neighbor_hover_modulate

var _hover_fade: HoverFade

func _init() -> void:
	super()
	_hover_fade = HoverFade.new()
	_hover_fade.control_to_fade = _fancy_text
	_hover_fade.trigger_control = self
	#_hover_fade.fade_behavior = fade_behavior
	#_hover_fade.fade_in_time = fade_in_time
	#_hover_fade.fade_in_delay = fade_in_delay
	#_hover_fade.fade_out_time = fade_out_time
	#_hover_fade.fade_out_delay = fade_out_delay
	#_hover_fade.hover_neighbors.assign(hover_neighbors.map(func(button: FancyHoverButton) -> HoverFade: return button._hover_fade))
	#_hover_fade.neighbor_hover_modulate = neighbor_hover_modulate
	add_child(_hover_fade, true, Node.INTERNAL_MODE_BACK)
