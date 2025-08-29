@tool
class_name CharacterConfirmation
extends ConfirmationDialog

signal name_changed(character_name: String)
signal character_confirmed(character_name: String)

@export_group("Configuration")
@export var _name: LineEdit

func _ready() -> void:
	_on_name_changed(_name.text)

func confirm() -> void:
	popup_centered()
	if _name.text.is_empty(): _name.grab_focus()

func set_character_name(character_name: String) -> void:
	_name.text = character_name
	get_ok_button().disabled = character_name.is_empty()

func _on_name_changed(new_text: String) -> void:
	get_ok_button().disabled = new_text.is_empty()
	name_changed.emit(new_text)

func _on_confirmed() -> void:
	character_confirmed.emit(_name.text)

func _on_name_submitted(new_text: String) -> void:
	if new_text.is_empty(): return
	name_changed.emit(new_text)
	character_confirmed.emit(new_text)
