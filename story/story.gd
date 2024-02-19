extends VBoxContainer

@export_group("Configuration")
@export var _title: RichTextLabel
@export var _sub_title: RichTextLabel

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Events.location_changed.connect(_on_location_changed)

func _on_location_changed(new_location: StoryLocation) -> void:
	_title.text = "[center]%s[/center]" % "Title"
	_sub_title.text = "[center]%s - %s[/center]" % ["Rocky Island", new_location.name]
