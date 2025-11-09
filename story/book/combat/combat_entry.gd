@tool
class_name CombatEntry
extends PageEntry

@export var story_page: StoryCombatPage

@export_group("Configuration")
@export var _stance_selection_buttons: StanceSelectionButtons
@export var _breath_dice_selection: BreathDiceSelection

var _save_request: SaveRequest :
	set(new_save_request):
		_save_request = new_save_request
		_breath_dice_selection.request_save(_save_request, _characters.get_character)
var _save_result: SaveResult

func enter_page() -> void:
	pass

func is_dice_page() -> bool:
	return true

func get_story_page() -> StoryCombatPage:
	return story_page

func set_story_page(new_story_page: StoryPage) -> void:
	assert(new_story_page is StoryCombatPage)
	story_page = new_story_page

func _set_state(new_state: State) -> void:
	super._set_state(new_state)
	match state:
		State.PAST: _stance_selection_buttons.disable_buttons()
		State.PRESENT: _stance_selection_buttons.enable_buttons()
		_: assert(false, "StoryEntry.State %s is not supported!" % state)
