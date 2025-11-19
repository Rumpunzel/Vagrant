class_name Mechanics
extends PanelContainer

@export var _party: Characters :
	set(new_party):
		assert(new_party)
		assert(not _party)
		_party = new_party
		_catch_breaths.characters = _party
		_update_catch_breath_button()
		_party.character_added.connect(_on_character_added)

@export_group("Configuration")
@export var _catch_breaths: CatchBreaths
@export var _catch_breath_button: Button

func _on_character_added(character: Character) -> void:
	character.breath_dice_changed.connect(_update_catch_breath_button.unbind(1))
	character.breath_dice_states_changed.connect(_update_catch_breath_button)

func _update_catch_breath_button() -> void:
	for character: Character in _party.characters.values():
		if character.can_catch_breath():
			_catch_breath_button.disabled = false
			return
	_catch_breath_button.disabled = true
