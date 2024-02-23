@tool
class_name DialogButton
extends Button

signal finished_setup
signal save_requested(save_request: SaveRequest, source: StoryDecision)

@export var story_decision: StoryDecision :
	set(new_story_decision):
		story_decision = new_story_decision
		_description.text = story_decision.to_dialog_button_text()
		_update_font_colors()

@export_group("Configuration")
@export var _container: Container
@export var _index: Label
@export var _description: TypingLabel

var _hovered := false
var _selected := false :
	set(new_selected):
		_selected = new_selected
		if _selected: _index.text = "✔"
		else: _set_index()

func _enter_tree() -> void:
	Story.decision_made.connect(_on_decision_made)

func _exit_tree() -> void:
	if Story.decision_made.is_connected(_on_decision_made): Story.decision_made.disconnect(_on_decision_made)

func _ready() -> void:
	visible = false
	_update_font_colors()
	_resize_to_fit_children()
	_set_index()
	var index := _set_index()
	if index > 9: return
	var number_shortcut := InputEventKey.new()
	number_shortcut.keycode = KEY_0 + index as Key
	shortcut = Shortcut.new()
	shortcut.events = [number_shortcut]

func popup(set_to_visible := true) -> void:
	visible = set_to_visible
	if not set_to_visible: return
	_description.type_text(story_decision.to_dialog_button_text())
	finished_setup.emit()

func _set_index() -> int:
	var index := get_index() + 1
	_index.text = "%d." % index
	return index

func _update_font_colors() -> void:
	_index.add_theme_color_override("font_color", _get_index_font_color())
	_description.add_theme_color_override("default_color", _get_text_font_color())

func _resize_to_fit_children() -> void:
	custom_minimum_size = _container.get_minimum_size()

func _get_index_font_color() -> Color:
	var index_color := get_theme_color("font_color")
	if _selected: pass
	elif disabled: index_color = get_theme_color("font_disabled_color")
	elif button_pressed:
		if _hovered: index_color = get_theme_color("font_hover_pressed_color")
		else: index_color = get_theme_color("font_pressed_color")
	elif _hovered: index_color = get_theme_color("font_hover_color")
	elif has_focus(): index_color = get_theme_color("font_focus_color")
	return index_color

func _get_text_font_color() -> Color:
	var text_color := get_theme_color("font_color")
	if _selected: pass
	elif disabled: text_color = get_theme_color("font_disabled_color")
	elif button_pressed:
		if _hovered: text_color = get_theme_color("font_hover_pressed_color")
		else: text_color = get_theme_color("font_pressed_color")
	elif Story.get_how_often_decision_has_been_made(story_decision) > 0:
		text_color = get_theme_color("font_disabled_color")
	elif _hovered: text_color = get_theme_color("font_hover_color")
	elif has_focus(): text_color = get_theme_color("font_focus_color")
	return text_color

func _on_pressed() -> void:
	if story_decision is StorySaveDecision:
		var save_request := (story_decision as StorySaveDecision).to_save_request()
		save_requested.emit(save_request, story_decision)
	else:
		save_requested.emit(null, story_decision)
		Story.make_decision(story_decision)

func _on_description_finished_typing() -> void:
	finished_setup.emit()

func _on_decision_made(selected_story_decision: StoryDecision, _selected_how_many_times: int) -> void:
	_selected = selected_story_decision == story_decision
	if _selected:
		focus_mode = Control.FOCUS_ALL
	else:
		focus_mode = Control.FOCUS_NONE
	disabled = true
	release_focus()
	_update_font_colors()
	Story.decision_made.disconnect(_on_decision_made)

func _on_container_minimum_size_changed() -> void:
	_resize_to_fit_children()

func _on_mouse_entered() -> void:
	_hovered = true
	_update_font_colors()

func _on_mouse_exited() -> void:
	_hovered = false
	_update_font_colors()
