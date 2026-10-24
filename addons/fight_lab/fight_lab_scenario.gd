@tool
class_name FightLabScenario
extends Resource

## Who the Fight Lab pits against each other: everyone on side A against everyone on side B, characters or monsters.
## Outcomes are told from side A's view. How often and how long they fight is up to the [FightLabRunSettings].

@export var side_a: Array[ActorProfile] = []
@export var side_b: Array[ActorProfile] = []
## How the characters on each side fight; monsters fight as their profile says
@export var strategy_a: FightLabStrategy
@export var strategy_b: FightLabStrategy

## Profiles that can't fight as they are (a character's attributes not rolled yet, as before character creation)
func get_skipped() -> Array[ActorProfile]:
	var skipped: Array[ActorProfile] = []
	skipped.assign((side_a + side_b).filter(func(profile: ActorProfile) -> bool: return not profile or not profile.can_fight()))
	return skipped

## One matchup per pairing across the sides, and per value of [param sweep] if there is one
func get_matchups(sweep: FightLabSweep = null) -> Array[FightLabMatchup]:
	var matchups: Array[FightLabMatchup] = []
	var skipped: Array[ActorProfile] = get_skipped()
	for a_index: int in side_a.size():
		if skipped.has(side_a[a_index]): continue
		for b_index: int in side_b.size():
			if skipped.has(side_b[b_index]): continue
			if not sweep:
				matchups.append(get_matchup(a_index, b_index))
				continue
			for value: int in sweep.get_values():
				var matchup: FightLabMatchup = get_matchup(a_index, b_index)
				matchup.sweep_value = value
				sweep.apply(value, matchup)
				matchups.append(matchup)
	return matchups

func get_matchup(a_index: int, b_index: int) -> FightLabMatchup:
	var matchup: FightLabMatchup = FightLabMatchup.new(side_a[a_index], side_b[b_index])
	matchup.strategy_a = strategy_a if strategy_a else FightLabStrategy.new()
	matchup.strategy_b = strategy_b if strategy_b else FightLabStrategy.new()
	matchup.a_index = a_index
	matchup.b_index = b_index
	return matchup
