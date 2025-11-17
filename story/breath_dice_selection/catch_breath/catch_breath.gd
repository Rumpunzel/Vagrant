class_name CatchBreath
extends PanelContainer

@export var character: Character :
	set(new_character):
		assert(new_character)
		if character:
			character.breath_dice_states_changed.disconnect(_on_breath_dice_states_changed)
		character = new_character
		_portrait.texture = character.character_profile.get_portrait(_portrait_identifier)
		_breath_dice.character = character
		update_die_types()
		var lost_breath_dice: Array[BreathDie] = character.get_lost_breath_dice()
		character.breath_dice_states_changed.connect(_on_breath_dice_states_changed)

@export var _portrait_identifier: String = "Small.png"

@export_group("Configuration")
@export var _portrait: TextureRect
@export var _die_selection: DieCarouselSelection
@export var _breath_dice: BreathDice

func update_die_types() -> void:
	#var spendable_breath_dice: Array[BreathDie] = character.get_spendable_breath_dice()
	#var spendable_die_types: Array[DieType] = []
	#for breath_die: BreathDie in spendable_breath_dice:
		#if not breath_die.die_type in spendable_die_types: spendable_die_types.append(breath_die.die_type)
	#_die_selection.die_types = spendable_die_types
	visible = character.can_catch_breath()

func _on_breath_dice_states_changed() -> void:
	update_die_types()
