extends VBoxContainer

@export_group("Configuration")
@export var _title: Label

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Events.location_changed.connect(_on_location_changed)

func _on_location_changed(new_location: StoryLocation) -> void:
	_title.text = new_location.name
