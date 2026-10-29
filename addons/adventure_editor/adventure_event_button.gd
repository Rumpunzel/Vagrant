@tool
class_name AdventureEventButton
extends Button

## An event in the map's sidebar; dragged onto a location, lists it there ([AdventureMapView]); pressed, opens it in the events tab

var event: AdventurePage

func _get_drag_data(_at_position: Vector2) -> Variant:
	var preview: Button = Button.new()
	preview.text = text
	set_drag_preview(preview)
	return {"adventure_event": event}
