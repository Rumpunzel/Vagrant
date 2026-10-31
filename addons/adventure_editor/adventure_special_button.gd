@tool
class_name AdventureSpecialButton
extends Button

## A special node in a section's title bar on the event screen; dragged onto the section's graph, places one there ([AdventureEventView])

## Its kind as [AdventureEventView] names it in layout keys: "host", "previous"
@export var kind: String

static func make(kind_name: String, label: String, tooltip: String, texture: Texture2D) -> AdventureSpecialButton:
	var button: AdventureSpecialButton = AdventureSpecialButton.new()
	button.kind = kind_name
	button.text = label
	button.tooltip_text = tooltip + " (drag it into the graph)"
	button.icon = texture
	button.flat = true
	button.expand_icon = true
	button.custom_minimum_size.y = 24
	return button

func _get_drag_data(_at_position: Vector2) -> Variant:
	var preview: Button = Button.new()
	preview.text = text
	preview.icon = icon
	preview.add_theme_constant_override(&"icon_max_width", 16)
	set_drag_preview(preview)
	return {"adventure_special": kind}
