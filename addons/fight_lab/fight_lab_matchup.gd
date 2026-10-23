class_name FightLabMatchup
extends RefCounted

## One cell of the Fight Lab: who fights whom, how the player fights, and the sweep value if any

var character_profile: CharacterProfile
var monster_profile: MonsterProfile
var strategy: FightLabStrategy
## Where the profiles sit in the scenario
var character_index: int = -1
var monster_index: int = -1
var sweep_value: int = 0

func _init(with_character_profile: CharacterProfile, with_monster_profile: MonsterProfile, with_strategy: FightLabStrategy) -> void:
	assert(with_character_profile and with_monster_profile and with_strategy)
	character_profile = with_character_profile
	monster_profile = with_monster_profile
	strategy = with_strategy
