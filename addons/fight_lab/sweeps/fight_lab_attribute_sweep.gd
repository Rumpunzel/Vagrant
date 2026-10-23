@tool
class_name FightLabAttributeSweep
extends FightLabSweep

## Sets one attribute score of the character or the monster to each value

enum Target {
	CHARACTER,
	MONSTER,
}

@export var target: Target = Target.CHARACTER
@export var attribute: CharacterAttribute

func get_label() -> String: return "%s %s" % ["Character" if target == Target.CHARACTER else "Monster", attribute.descriptor if attribute else "?"]

func apply(value: int, matchup: FightLabMatchup) -> void:
	assert(attribute)
	if target == Target.MONSTER:
		var monster_profile: MonsterProfile = matchup.monster_profile.duplicate()
		monster_profile.attribute_scores = matchup.monster_profile.attribute_scores.duplicate()
		monster_profile.attribute_scores[attribute] = value
		matchup.monster_profile = monster_profile
		return
	var character_profile: CharacterProfile = matchup.character_profile.duplicate()
	character_profile.attribute_scores = matchup.character_profile.attribute_scores.duplicate()
	# Origins may add to it; the rolled 2d6 make up the rest
	var first: int = clampi(floori(value / 2.0), 1, 6)
	character_profile.attribute_scores[attribute] = RolledAttributeScore.new([Die.new(Rules.d6, first), Die.new(Rules.d6, clampi(value - first, 1, 6))] as Array[Die])
	matchup.character_profile = character_profile
