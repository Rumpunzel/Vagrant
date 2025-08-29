class_name AttributeScore
extends RefCounted

enum Type {
	NORMAL,
	DOUBLE,
}

var attribute: CharacterAttribute
var base: BaseAttributeScore
var modifiers: Array[Modifier]

static func create(new_attribute: CharacterAttribute, new_rolled_dice: Array[Die]) -> AttributeScore:
	var new_attribute_score: BaseAttributeScore = BaseAttributeScore.new()
	new_attribute_score.rolled_dice = new_rolled_dice
	return create_with_modifiers(new_attribute, new_attribute_score, [])

static func create_with_modifiers(new_attribute: CharacterAttribute, new_base: BaseAttributeScore, new_modifiers: Array[Modifier]) -> AttributeScore:
	var new_attribute_score: AttributeScore = AttributeScore.new()
	new_attribute_score.attribute = new_attribute
	new_attribute_score.base = new_base
	new_attribute_score.modifiers = new_modifiers
	return new_attribute_score

func get_score() -> int:
	var score: int = base.get_score() 
	for modifier: Modifier in modifiers:
		score += modifier.modifier.score_modifiers[attribute]
	return score

func get_details(icon_size: int = 32) -> String:
	var details: String = "[ %s ]"
	var modifiers_details: Array[String] = []
	for modifier: Modifier in modifiers:
		var modifier_details: String = modifier.get_details(attribute, icon_size)
		if not modifier_details.is_empty(): modifiers_details.append(modifier_details)
	if not modifiers_details.is_empty(): details += " "
	details += "%s"
	return details % [base.get_dice(), " ".join(modifiers_details)]

func get_type() -> Type:
	return base.get_type()

class Modifier extends RefCounted:
	var modifier: AttributeScoreModifier
	var source: Origin
	
	func _init(new_modifier: AttributeScoreModifier, new_source: Origin) -> void:
		modifier = new_modifier
		source = new_source
	
	func get_details(attribute: CharacterAttribute, icon_size: int) -> String:
		return modifier.get_details(attribute, source, icon_size)
