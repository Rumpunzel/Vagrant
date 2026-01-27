@tool
class_name Origin
extends Background

enum Type {
	NORMAL,
	RARE,
}

@export_multiline var abilities: Array[String]
@export var modifiers: Array[AttributeScoreModifier]
@export var _ass: bool
@export var type: Type

static func concatenate(origins: Array[Origin]) -> String:
	var combination: OriginCombination = OriginCombination.find_combination(origins)
	if combination: return combination.name
	return " — ".join(origins.filter(func(origin: Origin) -> bool: return origin != null).map(func(origin: Origin) -> String: return origin.name))

static func concatenate_with_icons(origins: Array[Origin]) -> String:
	var combination: OriginCombination = OriginCombination.find_combination(origins)
	if combination:
		if combination.icon: return "%s [img=32x32,center,center]%s[/img]" % [combination, combination.icon.resource_path]
		else: return (" %s " % combination.name).join(origins.filter(func(origin: Origin) -> bool: return origin != null).map(func(origin: Origin) -> String: return "[img=32x32,center,center]%s[/img]" % origin.icon.resource_path))
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
		mods.append(AttributeScore.Modifier.new(modifier, icon, false))
	return mods

func get_lost_breath_dice(lost_breath_dice: Array[Die]) -> Array[Die]:
	if not _ass: return lost_breath_dice
	var highest_lost_breath_die: Die = null
	for lost_breath_die: Die in lost_breath_dice:
		var is_higher: bool = false
		if not highest_lost_breath_die: is_higher = true
		elif lost_breath_die.result > highest_lost_breath_die.result: is_higher = true
		elif lost_breath_die.result == highest_lost_breath_die.result and lost_breath_die.die_type.faces < highest_lost_breath_die.die_type.faces: is_higher = true
		if is_higher: highest_lost_breath_die = lost_breath_die
	if highest_lost_breath_die: return [highest_lost_breath_die]
	return lost_breath_dice
