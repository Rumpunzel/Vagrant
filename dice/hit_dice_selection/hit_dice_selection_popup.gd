extends Window

func _hide() -> void:
	if visible: hide()

func _on_dice_selection_configured(character: Character, attribute: CharacterAttribute) -> void:
	title = "[%s] %s Save" % [character.name, attribute]
	popup()

func _on_hit_dice_selection_confirmed(_save_result: SaveResult) -> void:
	pass#if visible: hide()

func _on_close_requested() -> void:
	_hide()
