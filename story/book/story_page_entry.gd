@tool
class_name StoryPageEntry
extends PanelContainer

enum State {
	PAST = -1,
	PRESENT,
}

@export var story_page: StoryPage
@export var state: State = State.PRESENT :
	set(new_state):
		state = new_state
		match state:
			State.PAST:
				for dialog_button: DialogButton in _choices.get_children(): dialog_button.active = false
				var tween: Tween = get_tree().create_tween()
				tween.tween_property(self, "modulate", _past_modulate, _fade_out_duration).set_delay(_dice_fade_out_delay if is_dice_page() else _fade_out_delay)
				_background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				if not _background.texture:
					_background.texture = story_page.get_area_background()
					var background_tween: Tween = get_tree().create_tween()
					background_tween.tween_property(_background, "modulate:a", 1.0, _dice_fade_out_delay)
				await tween.finished
				mouse_entered.connect(_on_mouse_entered)
				mouse_exited.connect(_on_mouse_exited)
			State.PRESENT:
				for dialog_button: DialogButton in _choices.get_children(): dialog_button.active = true
				modulate = Color.WHITE
			_: assert(false, "StoryPageEntry.State %s is not supported!" % state)

@export_range(0.0, 1.0) var _fade_in_duration: float = 0.1
@export_range(0.0, 1.0) var _dialog_options_fade_in_delay: float = 0.1

@export_range(0.0, 3.0) var _fade_out_duration: float = 1.0
@export_range(0.0, 1.0) var _fade_out_delay: float = 0.5
@export_range(0.0, 5.0) var _dice_fade_out_delay: float = 3.0
@export var _past_modulate: Color = Color(1.0, 1.0, 1.0, 0.25)

@export_group("Configuration")
@export var _background: TextureRect
@export var _description: TypingLabel
@export var _choices: Container
@export var _breath_dice_selection: BreathDiceSelection
@export var _breath_dice_selection_collapsible_container: CollapsibleContainer
@export var _dialog_button: PackedScene

var _story: Story
var _characters: Characters

var _selected_story_decision: StoryDecision
var _save_request: SaveRequest :
	set(new_save_request):
		_save_request = new_save_request
		_breath_dice_selection.request_save(_save_request, _characters.get_character)
		await get_tree().process_frame
		_breath_dice_selection_collapsible_container.open_tween()
var _save_result: SaveResult

func setup_page(story: Story, characters: Characters, new_story_page: StoryPage) -> void:
	_story = story
	_characters = characters
	story_page = new_story_page
	var background: Texture2D = story_page.get_background(_story)
	_background.texture = background
	if background:
		_background.expand_mode = TextureRect.EXPAND_FIT_HEIGHT_PROPORTIONAL
		_background.show_behind_parent = false
	else:
		_background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_background.show_behind_parent = true
	_update_decisions(story_page.get_decisions(_story))

func enter_page() -> void:
	_description.type_text(story_page.get_description(_story))
	_story.decision_made.connect(_on_decision_made)

func _exit_tree() -> void:
	if _story and _story.decision_made.is_connected(_on_decision_made): _story.decision_made.disconnect(_on_decision_made)

func is_dice_page() -> bool:
	assert(not _save_result or _save_request)
	return _save_result != null

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
	assert(save_request)
	assert(source)
	_selected_story_decision = source
	_save_request = save_request

func _on_save_evaluated(save_result: SaveResult) -> void:
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

func _on_mouse_entered() -> void:
	assert(state == State.PAST)
	if story_page.get_background(_story): _background.expand_mode = TextureRect.EXPAND_FIT_HEIGHT_PROPORTIONAL
	var tween: Tween = get_tree().create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, _fade_in_duration)

func _on_mouse_exited() -> void:
	assert(state == State.PAST)
	if get_global_rect().has_point(get_viewport().get_mouse_position()): return
	_background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	var tween: Tween = get_tree().create_tween()
	tween.tween_property(self, "modulate", _past_modulate, _fade_in_duration)
