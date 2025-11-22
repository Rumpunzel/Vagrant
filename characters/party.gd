@tool
class_name Party
extends Characters

signal character_selected(character: Character)

@export var _portrait_offset: Vector2i = Vector2i(0, -16)

@export_group("Configuration")
@export var _character_portraits: CharacterPortraits
@export var _character_sheet: PackedScene
@export var _popout_window: PackedScene

var _character_sheets: Dictionary[Character, CharacterSheet]
var _popout_windows: Dictionary[Character, PopoutWindow]

func _popup_above_portrait(character_portrait: CharacterPortrait) -> void:
	var popout_window: PopoutWindow = _popout_windows[character_portrait.character]
	popout_window.popup_above(character_portrait, _portrait_offset)

func _on_character_added(character: Character) -> void:
	var popout_window: PopoutWindow = _popout_window.instantiate()
	_popout_windows[character] = popout_window
	var character_sheet: CharacterSheet = _character_sheet.instantiate()
	character_sheet.character = character
	_character_sheets[character] = character_sheet
	popout_window.add(character_sheet)
	add_child(popout_window)

func _on_character_portraits_character_selected(character: Character, character_portrait: CharacterPortrait) -> void:
	assert(character)
	assert(character_portrait)
	var popout_window: PopoutWindow = _popout_windows[character]
	if popout_window.visible: popout_window.close()
	else: _popup_above_portrait(character_portrait)
	character_selected.emit(character)

func _on_dice_requested(dice_request: DiceRequest) -> void:
	for character: Character in _character_sheets.keys():
		var character_sheet: CharacterSheet = _character_sheets[character]
		if character == dice_request.character:
			character_sheet.update_dice_request(dice_request)
			var popout_window: PopoutWindow = _popout_windows[character]
			if not popout_window.visible: popout_window.popup_above(_character_portraits.get_character_portrait(dice_request.character), _portrait_offset)
		else: character_sheet.update_dice_request(null)
