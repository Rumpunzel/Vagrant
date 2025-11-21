class_name Mechanics
extends PanelContainer

@export var _party: Party :
	set(new_party):
		assert(new_party)
		assert(not _party)
		_party = new_party
		_catch_breaths.party = _party

@export_group("Configuration")
@export var _catch_breath_popup: ConfirmationDialog
@export var _catch_breaths: CatchBreaths
@export var _catch_breath_button: Button

func _ready() -> void:
	_catch_breath_popup.get_ok_button().mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_catch_breath_popup.get_cancel_button().mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

func _on_catch_breaths_status_changed(can_catch_breath: bool) -> void:
	_catch_breath_popup.get_ok_button().disabled = not can_catch_breath
	for character: Character in _party.characters.values():
		if character.can_catch_breath(null):
			_catch_breath_button.disabled = false
			return
	_catch_breath_button.disabled = not can_catch_breath
