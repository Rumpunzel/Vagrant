extends Window

const _TITLE_STRING := "[%s] %s Save"

func _hide() -> void:
	if visible: hide()

func _on_dice_selection_configured(character: Character, attribute: CharacterAttribute) -> void:
	title = _TITLE_STRING % [character.name, attribute]
	popup()

func _on_hit_dice_selection_confirmed(_save_result: SaveResult) -> void:
	pass#if visible: hide()

func _on_close_requested() -> void:
	_hide()
