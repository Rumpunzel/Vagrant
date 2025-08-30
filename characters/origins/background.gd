@tool
class_name Background
extends Resource

@export_placeholder("Name") var name: String
@export var icon: Texture2D
@export var color: Color
@export_multiline var details: String

func _to_string() -> String:
	return "[img=32x32,center,center]%s[/img] %s" % [icon.resource_path, name]
