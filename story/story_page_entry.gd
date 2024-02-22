@tool
class_name StoryPageEntry
extends PanelContainer

signal page_entered(story_page: StoryPage)

@export var story_page: StoryPage :
	set(new_story_page):
		story_page = new_story_page
		if story_page == null: return
		_background.visible = story_page.exclusive
		_background.texture = story_page.get_background()
		_description.type_text(story_page.get_description())
		_update_decisions(story_page.get_decisions())

@export_group("Configuration")
@export var _background: TextureRect
@export var _description: TypingLabel
@export var _choices: Container
@export var _hit_dice_selection: HitDiceSelection
@export var _hit_dice_selection_cc: CollapsibleContainer
@export var _dialog_button: PackedScene

var _selected_story_decision: StoryDecision
var _save_request: SaveRequest
var _save_result: SaveResult

func _progress_story(source: StoryDecision) -> void:
	print("SUCCESS!")
	_disable_buttons(source)
	page_entered.emit(source.transition.get_story_page())

func _handle_failure(source: StoryDecision) -> void:
	print("FAILURE!")
	_disable_buttons(source)
	page_entered.emit(source.failure_transition.get_story_page())

func _update_decisions(story_decisions: Array[StoryDecision]) -> void:
	for dialog_button: DialogButton in _choices.get_children():
		_choices.remove_child(dialog_button)
		dialog_button.queue_free()
	for story_decision: StoryDecision in story_decisions:
		var dialog_button: DialogButton = _dialog_button.instantiate()
		_choices.add_child(dialog_button)
		dialog_button.story_decision = story_decision
		dialog_button.story_continued.connect(_progress_story)
		dialog_button.save_requested.connect(_on_save_requested)
	if story_decisions.is_empty():
		var dialog_button: DialogButton = _dialog_button.instantiate()
		_choices.add_child(dialog_button)
		dialog_button.story_decision = StoryDecision.get_continue()
		dialog_button.story_continued.connect(_progress_story)

func _disable_buttons(selected_story_decision: StoryDecision) -> void:
	custom_minimum_size = Vector2.ZERO
	_background.visible = true
	for button: DialogButton in _choices.get_children():
		button.disable(selected_story_decision)

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
	_save_result = save_result
	if _save_result.save_outcome != SaveResult.Outcome.FAILURE:
		_progress_story(_selected_story_decision)
	else:
		_handle_failure(_selected_story_decision)

func _on_description_finished_typing() -> void:
	for button: DialogButton in _choices.get_children():
		button.popup()
		await button.finished_setup
