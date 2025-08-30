@tool
class_name AttributeScoreModifier
extends Resource

@export var score_modifiers: Dictionary[CharacterAttribute, int] = {
	Rules.STRENGTH: 1,
	Rules.AGILITY: 1,
	Rules.INTELLIGENCE: 1,
}

func get_details(attribute: CharacterAttribute, source: Origin, icon_size: int) -> String:
	assert(attribute)
	assert(source)
	var details: String = ""
	var score_modifier: int = score_modifiers[attribute]
	if score_modifier > 0: details += "+ [color=green]"
	elif score_modifier == 0: details += "+ "
	else: details += "- [color=red]"
	details += "%d" % score_modifier
	if score_modifier != 0: details += "[/color]"
	if source.icon: details += "[img=%dx%d,center,center]%s[/img]" % [icon_size, icon_size, source.icon.resource_path]
	return details
