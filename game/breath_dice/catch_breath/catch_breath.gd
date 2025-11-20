class_name CatchBreath
extends PanelContainer

signal status_changed

@export var character: Character :
	set(new_character):
		assert(new_character)
		if character:
			character.breath_dice_changed.disconnect(_on_breath_dice_changed.unbind(1))
			character.breath_dice_states_changed.disconnect(_on_breath_dice_changed)
			character.exhaustion_changed.disconnect(_on_exhaustion_changed)
		character = new_character
		_portrait.texture = character.character_profile.get_portrait(_portrait_identifier)
		_breath_dice.character = character
		update_die_types()
		update_exhaustion()
		character.breath_dice_changed.connect(_on_breath_dice_changed.unbind(1))
		character.breath_dice_states_changed.connect(_on_breath_dice_changed)
		character.exhaustion_changed.connect(_on_exhaustion_changed)

@export var _portrait_identifier: String = "Small.png"

@export_group("Configuration")
@export var _portrait: TextureRect
@export var _die_selection: DieCarouselSelection
@export var _breath_dice: BreathDice

var _die_to_exhaust: DieType :
	set(new_die_to_exhaust):
		_die_to_exhaust = new_die_to_exhaust
		_update_highlights()
		if not _die_to_exhaust: _breath_dice.stop_highlighting()
		status_changed.emit()

func catch_breath() -> bool:
	assert(_die_to_exhaust == _die_selection.get_selected_die_type())
	if not _die_to_exhaust or not can_catch_breath(): return false
	character.catch_breath(_die_to_exhaust)
	return true

func update_die_types() -> void:
	#visible = character.has_lost_breath()
	_die_selection.die_types = character.get_available_exhaustion()
	_die_selection.set_selected_die_type(character.get_smallest_exhaustion())
	_update_highlights()
	status_changed.emit()

func update_exhaustion() -> void:
	_breath_dice.set_exhaustion(character.exhaustion)
	_update_highlights()
	status_changed.emit()

func _update_highlights() -> void:
	_breath_dice.highlight(character.get_recoverable_breath_dice(_die_to_exhaust).keys())
	var potential_exhaustion: Array[DieType] = character.exhaustion.duplicate()
	if _die_to_exhaust: potential_exhaustion.append(_die_to_exhaust)
	for button_group: BreathDiceGroup in _breath_dice.button_groups.values(): button_group.exhaustion = potential_exhaustion

func can_catch_breath() -> bool:
	return _die_to_exhaust and character.can_catch_breath(_die_to_exhaust)

func _on_breath_dice_changed() -> void:
	update_die_types()
	status_changed.emit()

func _on_exhaustion_changed(exhaustion: Array[DieType]) -> void:
	assert(exhaustion == character.exhaustion)
	update_exhaustion()

func _on_die_type_selected(die_type: DieType) -> void:
	_die_to_exhaust = die_type
