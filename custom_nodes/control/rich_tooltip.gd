@tool
class_name RichTooltip
extends Tooltip

## The tooltip of a [RichTooltipTrigger], in the editor's tooltip look. Once it locks (its border lights up) its links show tooltips of their own
## and open what they name when clicked.

const WIDTH: float = 380.0

var _links: RichTooltipTrigger

func _ready() -> void:
	# Looked up rather than named: EditorInterface doesn't exist in exported games, and this script is part of the game's files
	var editor: Object = Engine.get_singleton(&"EditorInterface") if Engine.is_editor_hint() and Engine.has_singleton(&"EditorInterface") else null
	if editor != null:
		var theme: Theme = editor.call(&"get_editor_theme")
		add_theme_stylebox_override(&"panel", theme.get_stylebox(&"panel", &"TooltipPanel"))
		var border: StyleBoxFlat = StyleBoxFlat.new()
		border.draw_center = false
		border.set_border_width_all(1)
		border.border_color = theme.get_color(&"accent_color", &"Editor")
		border.set_corner_radius_all(3)
		for element: Control in lock_elements: element.add_theme_stylebox_override(&"panel", border)
	content_labels[0].custom_minimum_size.x = WIDTH

func set_content(tooltip_strings: Array[String]) -> void:
	super(tooltip_strings)
	var rich_trigger: RichTooltipTrigger = trigger as RichTooltipTrigger
	if _links != null or rich_trigger == null or not rich_trigger.describe_link.is_valid(): return
	_links = RichTooltipTrigger.new()
	_links.trigger_node = content_labels[0]
	_links.describe_link = rich_trigger.describe_link
	_links.open_link = rich_trigger.open_link
	_links.describer = rich_trigger.describer
	content_labels[0].add_child(_links)
	if rich_trigger.open_link.is_valid(): content_labels[0].meta_clicked.connect(rich_trigger.open_link)

## Links can only be hovered and clicked while locked; before, the mouse passes through to what is under it
func lock() -> void:
	super()
	content_labels[0].mouse_filter = Control.MOUSE_FILTER_PASS

func unlock() -> void:
	super()
	content_labels[0].mouse_filter = Control.MOUSE_FILTER_IGNORE
