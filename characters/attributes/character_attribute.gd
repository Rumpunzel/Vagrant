class_name CharacterAttribute
extends Resource

@export_placeholder("Descriptor") var descriptor: String
@export var color: Color

func _to_string() -> String:
	return descriptor
