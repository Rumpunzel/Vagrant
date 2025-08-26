class_name CharacterAttribute
extends Resource

@export_placeholder("Descriptor") var descriptor: String
@export var icon: Texture2D
@export var color: Color
@export_multiline var details: String

func _to_string() -> String:
	return descriptor
