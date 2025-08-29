@tool
class_name StoryPageEntry
extends PanelContainer

@export var story_page: StoryPage

@export_group("Configuration")
@export var _background: TextureRect
@export var _description: TypingLabel
@export var _choices: Container
@export var _hit_dice_selection: HitDiceSelection
@export var _hit_dice_selection_cc: CollapsibleContainer
@export var _dialog_button: PackedScene

var _story: Story
var _characters: Characters

var _selected_story_decision: StoryDecision
var _save_request: SaveRequest
var _save_result: SaveResult

func enter_page(story: Story, characters: Characters, new_story_page: StoryPage) -> void:
	_story = story
	_characters = characters
	story_page = new_story_page
	_background.texture = story_page.get_background(_story)
	_description.type_text(story_page.get_description(_story))
	_update_decisions(story_page.get_decisions(_story))
	_story.decision_made.connect(_on_decision_made)

func _exit_tree() -> void:
	if _story.decision_made.is_connected(_on_decision_made): _story.decision_made.disconnect(_on_decision_made)

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

func _on_save_requested(save_request: SaveRequest, source: StoryDecision) -> void:
	_save_request = save_request
	_selected_story_decision = source
	_hit_dice_selection.request_save(_save_request)
	if _save_request != null:
		await get_tree().process_frame
		_hit_dice_selection_cc.open_tween()
	else:
		_hit_dice_selection_cc.close()

func _on_save_evaluated(save_result: SaveResult) -> void:
	assert(_selected_story_decision is StorySaveDecision)
	_save_result = save_result
	_story.make_save_decision(_selected_story_decision as StorySaveDecision, _save_result)

func _on_description_finished_typing() -> void:
	for button: DialogButton in _choices.get_children():
		button.popup()
		await button.finished_setup

func _on_decision_made(_story_decision: StoryDecision, _selected_how_many_times: int) -> void:
	custom_minimum_size = Vector2.ZERO
	_background.visible = true
	_story.decision_made.disconnect(_on_decision_made)
