@tool
class_name FightLabScenario
extends Resource

## What the Fight Lab simulates: every character against every monster, for every sweep value, [member runs] times

@export var characters: Array[CharacterProfile] = []
@export var monsters: Array[MonsterProfile] = []
@export var strategy: FightLabStrategy
## Optional; without one, each matchup is simulated once as it is
@export var sweep: FightLabSweep
@export_range(1, 100000) var runs: int = 1000
## A fight still going after this many exchanges counts as unfinished
@export_range(1, 200) var max_exchanges: int = 50
## 0: a different seed every time
@export var random_seed: int = 0

## Characters that can't fight as they are (attributes not rolled yet, as before character creation)
func get_skipped_characters() -> Array[CharacterProfile]:
	var skipped: Array[CharacterProfile] = []
	skipped.assign(characters.filter(func(character_profile: CharacterProfile) -> bool: return not character_profile or not character_profile.has_valid_attributes()))
	return skipped

func get_matchups() -> Array[FightLabMatchup]:
	var matchups: Array[FightLabMatchup] = []
	var used_strategy: FightLabStrategy = strategy if strategy else FightLabStrategy.new()
	var skipped: Array[CharacterProfile] = get_skipped_characters()
	for character_profile: CharacterProfile in characters:
		if skipped.has(character_profile): continue
		for monster_profile: MonsterProfile in monsters:
			if not monster_profile: continue
			if not sweep:
				matchups.append(FightLabMatchup.new(character_profile, monster_profile, used_strategy))
				continue
			for value: int in sweep.get_values():
				var matchup: FightLabMatchup = FightLabMatchup.new(character_profile, monster_profile, used_strategy)
				matchup.sweep_value = value
				sweep.apply(value, matchup)
				matchups.append(matchup)
	return matchups
