class_name AdventureDecision
extends Resource

@export_multiline var description: String
@export var transition: AdventurePageReference
@export var consequences: Array[AdventureConsequence]

@export var _icon: Texture2D
@export var _color: Color = Color.WHITE

## Offered on pages without decisions; it has no transition, so it leads back to the previous page
static func get_turn_back() -> AdventureDecision:
	return load("uid://b4qjxus6rghvc")

func get_icon() -> Texture2D: return _icon
func get_color() -> Color: return _color
