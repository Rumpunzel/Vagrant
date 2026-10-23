@tool
class_name FightLabScenario
extends Resource

## Who the Fight Lab pits against each other: every character against every monster, the player fighting as [member strategy] says.
## How often and how long they fight is up to the [FightLabRunSettings].

@export var characters: Array[CharacterProfile] = []
@export var monsters: Array[MonsterProfile] = []
@export var strategy: FightLabStrategy

## Characters that can't fight as they are (attributes not rolled yet, as before character creation)
func get_skipped_characters() -> Array[CharacterProfile]:
	var skipped: Array[CharacterProfile] = []
	skipped.assign(characters.filter(func(character_profile: CharacterProfile) -> bool: return not character_profile or not character_profile.has_valid_attributes()))
	return skipped

## One matchup per character and monster, and per value of [param sweep] if there is one
func get_matchups(sweep: FightLabSweep = null) -> Array[FightLabMatchup]:
	var matchups: Array[FightLabMatchup] = []
	var skipped: Array[CharacterProfile] = get_skipped_characters()
	for character_index: int in characters.size():
		if skipped.has(characters[character_index]): continue
		for monster_index: int in monsters.size():
			if not monsters[monster_index]: continue
			if not sweep:
				matchups.append(get_matchup(character_index, monster_index))
				continue
			for value: int in sweep.get_values():
				var matchup: FightLabMatchup = get_matchup(character_index, monster_index)
				matchup.sweep_value = value
				sweep.apply(value, matchup)
				matchups.append(matchup)
	return matchups

func get_matchup(character_index: int, monster_index: int) -> FightLabMatchup:
	var matchup: FightLabMatchup = FightLabMatchup.new(characters[character_index], monsters[monster_index], strategy if strategy else FightLabStrategy.new())
	matchup.character_index = character_index
	matchup.monster_index = monster_index
	return matchup
