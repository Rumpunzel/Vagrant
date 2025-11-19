class_name CatchBreath
extends PanelContainer

@export var character: Character :
	set(new_character):
		assert(new_character)
		if character:
			character.breath_dice_changed.disconnect(_on_breath_dice_changed.unbind(1))
			character.breath_dice_states_changed.disconnect(_on_breath_dice_changed)
		character = new_character
		_portrait.texture = character.character_profile.get_portrait(_portrait_identifier)
		_breath_dice.character = character
		update_die_types()
		character.breath_dice_changed.connect(_on_breath_dice_changed.unbind(1))
		character.breath_dice_states_changed.connect(_on_breath_dice_changed)

@export var _portrait_identifier: String = "Small.png"

@export_group("Configuration")
@export var _portrait: TextureRect
@export var _die_selection: DieCarouselSelection
@export var _breath_dice: BreathDice

func catch_breath() -> void:
	if not character.can_catch_breath(): return
	character.catch_breath(_die_selection.get_selected_die_type())

func update_die_types() -> void:
	#visible = character.has_lost_breath()
	_die_selection.die_types = character.get_available_exhaustion()
	_die_selection.set_selected_die_type(character.get_smallest_exhaustion())
	_breath_dice.highlight(character.get_lost_breath_dice().keys())

func _on_breath_dice_changed() -> void:
	update_die_types()
