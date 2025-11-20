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
	if score_modifier < 0: details += "-"
	else: details += "+"
	var color: Color = Color.WHITE
	if score_modifier > 0: color = Main.SUCCESS
	elif score_modifier < 0: color = Main.FAILURE
	details += " [color=%s]%d[/color]" % [color.to_html(), abs(score_modifier)]
	if source_icon: details += " [img color=\"%s\" width=\"%d\" height=\"%d\" align=\"center\" valign=\"center\"]%s[/img]" % [color.to_html(), icon_size, icon_size, source_icon.resource_path]
	return details
