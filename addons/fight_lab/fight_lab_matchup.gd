class_name FightLabMatchup
extends RefCounted

## One cell of the Fight Lab: who fights whom, how the characters among them fight, and the sweep value if any

var profile_a: ActorProfile
var profile_b: ActorProfile
var strategy_a: FightLabStrategy
var strategy_b: FightLabStrategy
## Where the profiles sit on their sides in the scenario
var a_index: int = -1
var b_index: int = -1
var sweep_value: int = 0

func _init(with_profile_a: ActorProfile, with_profile_b: ActorProfile) -> void:
	assert(with_profile_a and with_profile_b)
	profile_a = with_profile_a
	profile_b = with_profile_b
