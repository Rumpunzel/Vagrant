@tool
@abstract
class_name BreathDiceGroup
extends FlexContainer

signal die_type_changed(die_type: DieType)
signal breath_die_button_added(breath_die_button: BreathDieButton)

@export var _die_type: DieType :
	set(new_die_type):
		_die_type = new_die_type
		die_type_changed.emit(_die_type)

@export var _breath_dice_count: int :
	set(new_breath_die_count):
		_breath_dice_count = new_breath_die_count
		clear()
		if _breath_dice_count <= 0:
			var dummy_button: BreathDieButton = _breath_die_button.instantiate()
			dummy_button.die_type = _die_type
			dummy_button.disabled = true
			dummy_button.flat = true
			dummy_button.tooltip_text = "All %s are lost." % _die_type
			dummy_button.mouse_default_cursor_shape = Control.CURSOR_FORBIDDEN
			add(dummy_button)
		for _index: int in range(_breath_dice_count): add_breath_die()
		_update_visibility()

@export_group("Configuration")
@export var _breath_die_button: PackedScene

var exhaustion: Array[DieType] : set = set_exhaustion

var _highlight_tween: Tween

func add_breath_die() -> void:
	assert(_die_type)
	var breath_die_button: BreathDieButton = _breath_die_button.instantiate()
	breath_die_button.die_type = _die_type
	add(breath_die_button)
	breath_die_button_added.emit(breath_die_button)

func highlight(frequency: float = 1.0) -> void:
	assert(frequency > 0.0)
	if _highlight_tween: _highlight_tween.kill()
	_highlight_tween = create_tween().set_loops()
	_highlight_tween.tween_property(self, "modulate:a", 0.5, 1.0 / frequency).set_trans(Tween.TRANS_CIRC).set_ease(Tween.EASE_IN).from(1.0)
	_highlight_tween.tween_property(self, "modulate:a", 1.0, 1.0 / frequency).set_trans(Tween.TRANS_CIRC).set_ease(Tween.EASE_IN).from(0.5)

func stop_highlighting() -> void:
	if _highlight_tween: _highlight_tween.kill()
	if is_exhausted(): return
	modulate.a = 1.0

func is_exhausted() -> bool: return exhaustion.has(_die_type)

func set_breath_dice_count(for_die_type: DieType, breath_dice_count: int) -> void:
	assert(for_die_type)
	_die_type = for_die_type
	_breath_dice_count = breath_dice_count

func set_exhaustion(new_exhaustion: Array[DieType]) -> void:
	exhaustion = new_exhaustion
	_update_visibility()

@abstract func _update_visibility() -> void
