@tool
class_name AdventureSpecialButton
extends Button

## A special node in the events tab's sidebar; dragged onto an event's frame, places one there ([AdventureEventView])

## Its kind as [AdventureEventView] names it in layout keys: "host", "previous"
@export var kind: String

func _get_drag_data(_at_position: Vector2) -> Variant:
	var preview: Button = Button.new()
	preview.text = text
	preview.icon = icon
	preview.add_theme_constant_override(&"icon_max_width", 16)
	set_drag_preview(preview)
	return {"adventure_special": kind}
