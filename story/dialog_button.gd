@tool
class_name DialogButton
extends Button

signal story_continued
signal save_requested(save_request: SaveRequest)

@export var story_decision: StoryDecision :
	set(new_story_decision):
		story_decision = new_story_decision
		_description.text = story_decision.to_dialog_button_text()

@export_group("Configuration")
@export var _container: Container
@export var _index: Label
@export var _description: RichTextLabel

var _hovered := false

func _ready() -> void:
	_index.text = "%d." % [get_index() + 1]
	_update_font_colors()
	_resize_to_fit_children()

func disable(set_to_disabled := true) -> void:
	focus_mode = Control.FOCUS_ALL if not set_to_disabled or button_pressed else Control.FOCUS_NONE
	disabled = set_to_disabled
	_update_font_colors()

func _update_font_colors() -> void:
	var new_color := get_theme_color("font_color")
	if button_pressed:
		if disabled: pass
		if _hovered: new_color = get_theme_color("font_hover_pressed_color")
		else: new_color = get_theme_color("font_pressed_color")
	elif disabled: new_color = get_theme_color("font_disabled_color")
	elif _hovered:
		new_color = get_theme_color("font_hover_color")
	elif has_focus():
		new_color = get_theme_color("font_focus_color")
	_index.add_theme_color_override("font_color", new_color)
	_description.add_theme_color_override("default_color", new_color)

func _resize_to_fit_children() -> void:
	custom_minimum_size = _container.get_minimum_size()

func _on_pressed() -> void:
	_index.text = "✔"
	if story_decision.attribute != null:
		var save_request := story_decision.to_save_request()
		save_requested.emit(save_request)
	else:
		story_continued.emit()

func _on_container_minimum_size_changed() -> void:
	_resize_to_fit_children()

func _on_mouse_entered() -> void:
	_hovered = true
	_update_font_colors()

func _on_mouse_exited() -> void:
	_hovered = false
	_update_font_colors()
