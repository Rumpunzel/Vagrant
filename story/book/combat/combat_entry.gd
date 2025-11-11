@tool
class_name CombatEntry
extends PageEntry

@export var story_page: StoryCombatPage

@export_group("Configuration")
@export var _breath_dice_selection: BreathDiceSelection
@export var _stance_selection_buttons: StanceSelectionButtons

var _fight_request: FightRequest :
	set(new_fight_request):
		_fight_request = new_fight_request
		_breath_dice_selection.request_fight(_fight_request)
		_stance_selection_buttons.request_fight(_fight_request)
var _save_result: SaveResult

func enter_page() -> void:
	_fight_request = story_page.to_fight_request(_characters.get_protagonist())

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
