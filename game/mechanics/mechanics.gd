class_name Mechanics
extends PanelContainer

@export var _party: Party :
	set(new_party):
		assert(new_party)
		assert(not _party)
		_party = new_party
		_catch_breaths.party = _party
		_make_camps.party = _party

@export_group("Configuration")
@export var _catch_breath_popup: ConfirmationDialog
@export var _catch_breaths: CatchBreaths
@export var _make_camp_popup: ConfirmationDialog
@export var _make_camps: MakeCamps
@export var _catch_breath_button: Button
@export var _make_camp_button: Button

var _can_catch_breath: bool = false
## Resting is not possible while a fight goes on
var _is_fighting: bool = false

func _ready() -> void:
	_catch_breath_popup.get_ok_button().mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_catch_breath_popup.get_cancel_button().mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_make_camp_popup.get_ok_button().mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_make_camp_popup.get_cancel_button().mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

func _on_story_page_entered(story_page: StoryPage) -> void:
	_is_fighting = story_page.is_fighting()
	_update_buttons()

func _on_catch_breaths_status_changed(can_catch_breath: bool) -> void:
	_can_catch_breath = can_catch_breath
	_catch_breath_popup.get_ok_button().disabled = not can_catch_breath
	_update_buttons()

func _update_buttons() -> void:
	_make_camp_button.disabled = _is_fighting
	_catch_breath_button.disabled = _is_fighting or not (_can_catch_breath or _party.characters.values().any(func(character: Character) -> bool: return character.can_catch_breath(null)))
