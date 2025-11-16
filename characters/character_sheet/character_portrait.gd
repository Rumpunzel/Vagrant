@tool
class_name CharacterPortrait
extends PanelContainer

signal character_selected(character: Character)

@export var character: Character :
	set(new_character):
		if new_character == character: return
		if character != null:
			character.character_profile_changed.disconnect(_on_character_profile_changed)
			character.breath_dice_changed.disconnect(_breath_dice.setup_breath_dice)
			character.save_requested.disconnect(_on_save_requested)
			character.fight_requested.disconnect(_on_fight_requested)
		character = new_character
		character.character_profile_changed.connect(_on_character_profile_changed)
		character.breath_dice_changed.connect(_breath_dice.setup_breath_dice)
		character.save_requested.connect(_on_save_requested)
		character.fight_requested.connect(_on_fight_requested)
		_update()
		_breath_dice.setup_breath_dice(character.breath_dice)

@export var _portrait_identifier: String = "Small.png"

@export_group("Configuration")
@export var _button: DisplayButton
@export var _portrait: TextureRect
@export var _breath_dice: BreathDice

func setup(button_group: ButtonGroup) -> void:
	_button.button_group = button_group

func select() -> void:
	_button.button_pressed = true
	_on_button_pressed()

func _update() -> void:
	var character_profile: CharacterProfile = character.character_profile
	_portrait.texture = character_profile.get_portrait(_portrait_identifier)

func _on_character_profile_changed(_character_profile: CharacterProfile) -> void:
	_update()

func _on_save_requested(_save_request: SaveRequest) -> void:
	select()

func _on_fight_requested(_fight_request: FightRequest) -> void:
	select()

func _on_button_pressed() -> void:
	character_selected.emit(character)
