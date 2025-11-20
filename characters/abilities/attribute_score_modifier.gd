@tool
class_name AttributeScoreModifier
extends Resource

@export_multiline var description: String
@export var score_modifiers: Dictionary[CharacterAttribute, int] = {
	Rules.STRENGTH: 1,
	Rules.AGILITY: 1,
	Rules.INTELLIGENCE: 1,
}

func get_details(attribute: CharacterAttribute, source_icon: Texture2D, icon_size: int) -> String:
	assert(attribute)
	var details: String = ""
	var score_modifier: int = score_modifiers[attribute]
	if score_modifier > 0: details += "+ [color=lime_green]"
	elif score_modifier == 0: details += "+ "
	else: details += "- [color=firebrick]"
	details += "%d" % abs(score_modifier)
	if score_modifier != 0: details += "[/color]"
	if source_icon: details += "[img=%dx%d,center,center]%s[/img]" % [icon_size, icon_size, source_icon.resource_path]
	return details
