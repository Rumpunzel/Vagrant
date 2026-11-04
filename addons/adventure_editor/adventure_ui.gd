@tool
class_name AdventureUi
extends RefCounted

## The adventure editor's controls, so every view looks and works the same: a checkbox for on and off, a button group for a few options
## (all visible, one pressed), icon buttons for actions. Icons are the editor's ([method AdventureActionMenu.get_editor_icon]); where
## there is no editor (previews), [param fallback] text stands in.

const FADED: Color = Color(1, 1, 1, 0.5)

## A flat action button showing only its icon
static func icon_button(icon_name: String, fallback: String, tooltip: String, on_pressed: Callable) -> Button:
	var button: Button = Button.new()
	button.flat = true
	button.icon = AdventureActionMenu.get_editor_icon(icon_name)
	if button.icon == null: button.text = fallback
	button.tooltip_text = tooltip
	button.pressed.connect(on_pressed)
	return button

## An action button with its text, and an icon if [param icon_name] names one
static func text_button(text: String, icon_name: String, tooltip: String, on_pressed: Callable) -> Button:
	var button: Button = Button.new()
	button.text = text
	if not icon_name.is_empty(): button.icon = AdventureActionMenu.get_editor_icon(icon_name)
	button.tooltip_text = tooltip
	button.pressed.connect(on_pressed)
	return button

## On or off; [param on_toggled] gets the new state
static func check(text: String, on: bool, tooltip: String, on_toggled: Callable) -> CheckBox:
	var box: CheckBox = CheckBox.new()
	box.text = text
	box.button_pressed = on
	box.tooltip_text = tooltip
	box.toggled.connect(on_toggled)
	return box

## [param caption] and one button per option, [param picked] pressed; [param on_picked] gets another option's index when it is pressed
static func choice(caption: String, options: Array[String], picked: int, tooltips: Array[String], on_picked: Callable) -> HBoxContainer:
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 0)
	if not caption.is_empty():
		row.add_child(info(caption))
		row.add_child(spacer(6))
	var group: ButtonGroup = ButtonGroup.new()
	for index: int in options.size():
		var option: Button = Button.new()
		option.text = options[index]
		option.toggle_mode = true
		option.button_group = group
		option.button_pressed = index == picked
		option.theme_type_variation = &"FlatButton" if index != picked else &""
		if index < tooltips.size(): option.tooltip_text = tooltips[index]
		if index != picked: option.pressed.connect(on_picked.bind(index))
		row.add_child(option)
	return row

static func label(text: String) -> Label:
	var made: Label = Label.new()
	made.text = text
	made.mouse_filter = Control.MOUSE_FILTER_PASS
	return made

## Faded, for what explains rather than says
static func info(text: String) -> Label:
	var made: Label = label(text)
	made.modulate = FADED
	return made

static func spacer(width: float) -> Control:
	var space: Control = Control.new()
	space.custom_minimum_size.x = width
	space.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return space
