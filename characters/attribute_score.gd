class_name AttributeScore
extends RefCounted

enum Type {
	NORMAL,
	DOUBLE,
}

var _attribute: CharacterAttribute
var _base: RolledAttributeScore
var _internal_modifiers: Array[Modifier]
var _external_modifiers: Array[Modifier]

func _init(attribute: CharacterAttribute, base: RolledAttributeScore, internal_modifiers: Array[Modifier], external_modifiers: Array[Modifier] = []) -> void:
	assert(attribute)
	assert(base)
	_attribute = attribute
	_base = base
	_internal_modifiers = internal_modifiers
	_external_modifiers = external_modifiers

static func create(attribute: CharacterAttribute, rolled_dice: Array[Die]) -> AttributeScore:
	var attribute_score: RolledAttributeScore = RolledAttributeScore.new(rolled_dice)
	return new(attribute, attribute_score, [])

func get_score() -> int:
	return _base.get_score() + get_internal_modifier_sum() + get_external_modifier_sum()

func get_internal_modifier_sum() -> int:
	var sum: int = 0
	for modifier: Modifier in _internal_modifiers:
		sum += modifier.modifier.score_modifiers[_attribute]
	return sum

func get_external_modifier_sum() -> int:
	var sum: int = 0
	for modifier: Modifier in _external_modifiers:
		sum += modifier.modifier.score_modifiers[_attribute]
	return sum

func get_color() -> Color:
	var external_modifier_sum: int = get_external_modifier_sum()
	if external_modifier_sum > 0: return Main.SUCCESS
	if external_modifier_sum < 0: return Main.FAILURE
	return Color.WHITE

func get_details(icon_size: int = 32) -> String:
	var details: String = ""
	if _base.get_type() == AttributeScore.Type.DOUBLE: details += "[color=gold]"
	details += _base.to_string()
	details += " [img=%dx%d,center,center]%s[/img]" % [icon_size, icon_size, "uid://dpmwlpo7a7q1r"]
	if _base.get_type() == AttributeScore.Type.DOUBLE: details += "[/color]"
	var internal_modifiers_details: Array[String] = []
	for modifier: Modifier in _internal_modifiers:
		var modifier_details: String = modifier.get_details(_attribute, icon_size)
		if not modifier_details.is_empty(): internal_modifiers_details.append(modifier_details)
	if not internal_modifiers_details.is_empty(): details += " "
	details += " ".join(internal_modifiers_details)
	var external_modifiers_details: Array[String] = []
	for modifier: Modifier in _external_modifiers:
		var modifier_details: String = modifier.get_details(_attribute, icon_size)
		if not modifier_details.is_empty(): external_modifiers_details.append(modifier_details)
	if not external_modifiers_details.is_empty(): details += " "
	details += " ".join(external_modifiers_details)
	return details

class Modifier extends RefCounted:
	var modifier: AttributeScoreModifier
	var source_icon: Texture2D
	
	func _init(new_modifier: AttributeScoreModifier, new_source_icon: Texture2D) -> void:
		modifier = new_modifier
		source_icon = new_source_icon
	
	func get_details(attribute: CharacterAttribute, icon_size: int) -> String:
		return modifier.get_details(attribute, source_icon, icon_size)
