@tool
class_name FightLabAttributeSweep
extends FightLabSweep

## Sets one attribute score of the fighter on side A or B to each value (a character's rolled 2d6; origins still add to it)

enum Team {
	A,
	B,
}

@export var side: Team = Team.A
@export var attribute: CharacterAttribute

func get_label() -> String: return "%s %s" % ["Side A" if side == Team.A else "Side B", attribute.descriptor if attribute else "?"]

func apply(value: int, matchup: FightLabMatchup) -> void:
	assert(attribute)
	if side == Team.A: matchup.profile_a = matchup.profile_a.with_attribute_score(attribute, value)
	else: matchup.profile_b = matchup.profile_b.with_attribute_score(attribute, value)
