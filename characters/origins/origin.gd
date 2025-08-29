@tool
class_name Origin
extends Resource

enum Type {
	NORMAL,
	RARE,
}

@export_placeholder("Name") var name: String
@export var icon: Texture2D
@export var type: Type
@export var color: Color
@export_multiline var details: String
@export_multiline var abilities: Array[String]
