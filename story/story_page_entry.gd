@tool
class_name StoryPageEntry
extends VBoxContainer

signal new_page_requested(story_page: StoryPage)
signal hit_dice_selection_added(hit_dice_selection: HitDiceSelection)

@export var story_page: StoryPage :
	set(new_story_page):
		story_page = new_story_page
		_description.text = story_page.description
		_update_decisions(story_page.decisions)

@export_group("Configuration")
@export var _description: RichTextLabel
@export var _choices: Container
@export var _dialog_button: PackedScene
@export var _hit_dice_selection: PackedScene

var _selected_story_decision: StoryDecision
var _save_request: SaveRequest
var _save_result: SaveResult

func _progress_story(source: StoryDecision) -> void:
	print("SUCCESS!")
	new_page_requested.emit(source.next_story_page)

func _handle_failure(source: StoryDecision) -> void:
	print("FAILURE!")
	new_page_requested.emit(source.failure_story_page)

func _update_decisions(story_decisions: Array[StoryDecision]) -> void:
	for dialog_button: DialogButton in _choices.get_children():
		_choices.remove_child(dialog_button)
		dialog_button.queue_free()
	for story_decision: StoryDecision in story_decisions:
		var dialog_button: DialogButton = _dialog_button.instantiate()
		dialog_button.story_decision = story_decision
		dialog_button.story_continued.connect(_progress_story)
		dialog_button.save_requested.connect(_on_save_requested)
		_choices.add_child(dialog_button)

func _on_save_requested(save_request: SaveRequest, source: StoryDecision) -> void:
	_save_request = save_request
	_selected_story_decision = source
	var hit_dice_selection: HitDiceSelection = _hit_dice_selection.instantiate()
	hit_dice_selection.request_save(_save_request)
	hit_dice_selection.save_evaluated.connect(_on_save_evaluated)
	add_child(hit_dice_selection)
	for button: DialogButton in _choices.get_children():
		button.disable()
	await get_tree().process_frame
	hit_dice_selection_added.emit(hit_dice_selection)

func _on_save_evaluated(save_result: SaveResult) -> void:
	_save_result = save_result
	if _save_result.save_outcome != SaveResult.Outcome.FAILURE:
		_progress_story(_selected_story_decision)
	else:
		_handle_failure(_selected_story_decision)
