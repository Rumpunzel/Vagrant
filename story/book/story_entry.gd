@tool
class_name StoryEntry
extends PageEntry

@export var story_page: StoryPage
@export_range(0.0, 1.0) var _dialog_options_fade_in_delay: float = 0.1

@export_group("Configuration")
@export var _title: TypingLabel
@export var _description: TypingLabel
@export var _choices: Container
@export var _breath_dice_selection: BreathDiceSelection
@export var _breath_dice_selection_collapsible_container: CollapsibleContainer
@export var _dialog_button: PackedScene

var _selected_story_decision: StoryDecision
var _save_request: SaveRequest :
	set(new_save_request):
		_save_request = new_save_request
		_breath_dice_selection.request_save(_save_request)
		await get_tree().process_frame
		_breath_dice_selection_collapsible_container.open_tween()
var _save_result: SaveResult

func setup_page(story: Story, characters: Characters, new_story_page: StoryPage) -> void:
	super.setup_page(story, characters, new_story_page)
	_update_decisions(story_page.get_decisions(_story))

func enter_page() -> void:
	var title: String = story_page.get_page_title(_story)
	if not title.is_empty(): _title.type_text(title)
	else: _title.visible = false
	_description.type_text(story_page.get_description(_story))
	_story.decision_made.connect(_on_decision_made)

func _exit_tree() -> void:
	if _story and _story.decision_made.is_connected(_on_decision_made): _story.decision_made.disconnect(_on_decision_made)

func is_dice_page() -> bool:
	assert(not _save_result or _save_request)
	return _save_result != null

func get_story_page() -> StoryPage:
	return story_page

func set_story_page(new_story_page: StoryPage) -> void:
	story_page = new_story_page

func _update_decisions(story_decisions: Array[StoryDecision]) -> void:
	for dialog_button: DialogButton in _choices.get_children():
		_choices.remove_child(dialog_button)
		dialog_button.queue_free()
	for story_decision: StoryDecision in story_decisions:
		var dialog_button: DialogButton = _create_dialog_button(story_decision)
		dialog_button.save_requested.connect(_on_save_requested)
	if story_decisions.is_empty():
		_create_dialog_button(StoryDecision.get_continue())

func _create_dialog_button(story_decision: StoryDecision) -> DialogButton:
	var dialog_button: DialogButton = _dialog_button.instantiate()
	dialog_button.setup(_story, _characters, story_decision)
	_choices.add_child(dialog_button)
	return dialog_button

func _set_state(new_state: State) -> void:
	super._set_state(new_state)
	match state:
		State.PAST:
			for dialog_button: DialogButton in _choices.get_children(): dialog_button.active = false
		State.PRESENT:
			for dialog_button: DialogButton in _choices.get_children(): dialog_button.active = true
		_: assert(false, "StoryEntry.State %s is not supported!" % state)

func _on_save_requested(save_request: SaveRequest, source: StoryDecision) -> void:
	assert(save_request)
	assert(source)
	_selected_story_decision = source
	_save_request = save_request
	_save_request.save_rolled.connect(_on_save_rolled)

func _on_save_rolled(save_result: SaveResult) -> void:
	assert(_selected_story_decision is StorySaveDecision)
	_save_result = save_result
	_story.make_save_decision(_selected_story_decision as StorySaveDecision, _save_result)

func _on_description_finished_typing() -> void:
	var buttons: Array[DialogButton] = []
	buttons.assign(_choices.get_children())
	for index: int in buttons.size():
		var button: DialogButton = buttons[index]
		button.popup(_dialog_options_fade_in_delay * index)

func _on_decision_made(_story_decision: StoryDecision, _selected_how_many_times: int) -> void:
	_description.set_text_normally()
	state = State.PAST
	_story.decision_made.disconnect(_on_decision_made)

func _on_breath_dice_selection_confirmed() -> void:
	assert(_save_request)
	_save_request.roll_save()
