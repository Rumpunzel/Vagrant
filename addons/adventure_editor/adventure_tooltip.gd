@tool
class_name AdventureTooltip
extends Tooltip

## The adventure editor's tooltip ([AdventureTooltipTrigger]), in the editor's tooltip look. Once it locks (its border lights up) its links
## show tooltips of their own and open what they name when clicked.

const WIDTH: float = 380.0

var _links: AdventureTooltipTrigger

func _ready() -> void:
	if not Engine.is_editor_hint(): return
	var theme: Theme = EditorInterface.get_editor_theme()
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
	var adventure_trigger: AdventureTooltipTrigger = trigger as AdventureTooltipTrigger
	if _links != null or adventure_trigger == null: return
	_links = adventure_trigger.tooltips.attach_links(content_labels[0])
	content_labels[0].meta_clicked.connect(adventure_trigger.tooltips.open_link)

## Links can only be hovered and clicked while locked; before, the mouse passes through to what is under it
func lock() -> void:
	super()
	content_labels[0].mouse_filter = Control.MOUSE_FILTER_PASS

func unlock() -> void:
	super()
	content_labels[0].mouse_filter = Control.MOUSE_FILTER_IGNORE
