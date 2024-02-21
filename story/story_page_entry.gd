@tool
class_name StoryPageEntry
extends PanelContainer

signal page_entered(story_page: StoryPage)

@export var story_page: StoryPage :
	set(new_story_page):
		story_page = new_story_page
		var description := ""
		var decisions: Array[StoryDecision] = [ ]
		var is_exclusive := false
		if story_page is StoryLocation:
			for event: StoryEvent in story_page.events:
				if event.are_all_prerequisites_fullfilled():
					if event.exclusive:
						description = event.description
						decisions = event.decisions
						is_exclusive = true
						break
					else:
						description += "[p]%s[/p]" % event.description
						decisions.append_array(event.decisions)
		if not is_exclusive:
			description = ("[p]%s[/p]" % story_page.description) + description
			decisions.append_array(story_page.decisions)
		_description.type_text(description)
		_update_decisions(decisions)

@export_group("Configuration")
@export var _hit_dice_selection: HitDiceSelection
@export var _description: TypingLabel
@export var _choices: Container
@export var _dialog_button: PackedScene

var _selected_story_decision: StoryDecision
var _save_request: SaveRequest
var _save_result: SaveResult

func _enter_tree() -> void:
	_hit_dice_selection.visible = false

func _progress_story(source: StoryDecision) -> void:
	print("SUCCESS!")
	_disable_buttons(source)
	page_entered.emit(source.transition.get_next_page())

func _handle_failure(source: StoryDecision) -> void:
	print("FAILURE!")
	_disable_buttons(source)
	page_entered.emit(source.failure_transition.get_next_page())

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
	for button: DialogButton in _choices.get_children():
		button.disable(selected_story_decision)

func _on_save_requested(save_request: SaveRequest, source: StoryDecision) -> void:
	_save_request = save_request
	_selected_story_decision = source
	_hit_dice_selection.request_save(_save_request)
	_hit_dice_selection.visible = save_request != null

func _on_save_evaluated(save_result: SaveResult) -> void:
	_save_result = save_result
	if _save_result.save_outcome != SaveResult.Outcome.FAILURE:
		_progress_story(_selected_story_decision)
	else:
		_handle_failure(_selected_story_decision)
