class_name CharacterAttribute
extends Resource

@export_placeholder("Descriptor") var descriptor: String
@export var icon: Texture2D
@export var color: Color
@export_multiline var details: String
@export_multiline var stance_description: String
@export_multiline var abilities: Array[String]

func _to_string() -> String:
	return descriptor
