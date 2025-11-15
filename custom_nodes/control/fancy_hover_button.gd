@tool
class_name FancyHoverButton
extends FancyButton

@export var fade_behavior: HoverFade.Behavior :
	get: return _hover_fade.fade_behavior
	set(new_fade_behavior): _hover_fade.fade_behavior = new_fade_behavior
@export var fade_in_time: float = 0.1 :
	get: return _hover_fade.fade_in_time
	set(new_fade_in_time): _hover_fade.fade_in_time = new_fade_in_time
@export var fade_in_delay: float :
	get: return _hover_fade.fade_in_delay
	set(new_fade_in_delay): _hover_fade.fade_in_delay = new_fade_in_delay
@export var fade_out_time: float = 0.1 :
	get: return _hover_fade.fade_out_time
	set(new_fade_out_time): _hover_fade.fade_out_time = new_fade_out_time
@export var fade_out_delay: float = 0.1 :
	get: return _hover_fade.fade_out_delay
	set(new_fade_out_delay): _hover_fade.fade_out_delay = new_fade_out_delay

@export_group("Neighbors")
@export var hover_neighbors: Array[FancyHoverButton] :
	set(new_hover_neighbors):
		hover_neighbors = new_hover_neighbors
		_hover_fade.hover_neighbors.assign(hover_neighbors.map(func(button: FancyHoverButton) -> HoverFade: return button._hover_fade))
@export var neighbor_hover_modulate: Color = Color(1.0, 1.0, 1.0, 0.25) :
	get: return _hover_fade.neighbor_hover_modulate
	set(new_neighbor_hover_modulate): _hover_fade.neighbor_hover_modulate = new_neighbor_hover_modulate

var _hover_fade: HoverFade

func _init() -> void:
	super()
	_hover_fade = HoverFade.new()
	_hover_fade.control_to_fade = _fancy_text
	_hover_fade.trigger_control = self
	add_child(_hover_fade, true, Node.INTERNAL_MODE_BACK)
