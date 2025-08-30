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
@export var modifiers: Array[AttributeScoreModifier]

static func concatenate(origins: Array[Origin]) -> String:
	return " — ".join(origins.map(func(origin: Origin) -> String: return origin.name))

static func concatenate_with_icons(origins: Array[Origin]) -> String:
	var origins_with_icons: Array[String] = []
	for index: int in origins.size():
		var origin: Origin = origins[index]
		var origin_icon: String = "[img=32x32,center,center]%s[/img]" % origin.icon.resource_path
		var origin_with_icon: String = ""
		@warning_ignore("integer_division")
		if index < origins.size() / 2: origin_with_icon += "%s " % origin_icon
		origin_with_icon += origin.name
		@warning_ignore("integer_division")
		if index >= origins.size() / 2: origin_with_icon += " %s" % origin_icon
		origins_with_icons.append(origin_with_icon)
	return " — ".join(origins_with_icons)

func get_attribute_score_modifiers() -> Array[AttributeScore.Modifier]:
	var mods: Array[AttributeScore.Modifier] = []
	for modifier: AttributeScoreModifier in modifiers:
		mods.append(AttributeScore.Modifier.new(modifier, self))
	return mods

func _to_string() -> String:
	return "[img=32x32,center,center]%s[/img] %s" % [icon.resource_path, name]
