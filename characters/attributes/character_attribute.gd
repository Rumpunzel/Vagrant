class_name CharacterAttribute
extends Resource

@export_placeholder("Descriptor") var descriptor: String
@export var icon: Texture2D
@export var fight_icon: Texture2D
@export var color: Color
@export_multiline var details: String
@export_multiline var stance_description: String
@export_multiline var abilities: Array[String]

func to_bbcode(icon_size: int = 24) -> String:
	return "[img color=\"%s\" width=\"%d\" height=\"%d\" align=\"center\" valign=\"center\"]%s[/img]" % [color.to_html(), icon_size, icon_size, icon.resource_path]

func _to_string() -> String:
	return descriptor
