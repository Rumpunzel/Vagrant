@tool
class_name CharacterPortrait
extends CharacterPanel

signal character_selected(character: Character)

@export var _portrait_identifier: String = "Small.png"

@export_group("Configuration")
@export var _button: DisplayButton
@export var _breath_dice: BreathDice

func setup(button_group: ButtonGroup) -> void:
	_button.button_group = button_group

func select() -> void:
	if not _button.button_pressed: _button.button_pressed = true
	else: character_selected.emit(character)

func select_no_signal() -> void:
	_button.set_pressed_no_signal(true)

func _update_portrait() -> void:
	_portrait.texture = _character_profile.get_portrait(_portrait_identifier)

func _get_breath_dice() -> BreathDice: return _breath_dice

func _on_save_requested(_save_request: SaveRequest) -> void:
	select()

func _on_fight_requested(_fight_request: FightRequest) -> void:
	select()

func _on_button_pressed() -> void:
	character_selected.emit(character)
