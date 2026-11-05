@tool
class_name FightLabScenario
extends Resource

## Who the Fight Lab pits against each other: everyone on side A against everyone on side B, characters or monsters.
## Outcomes are told from side A's view. How often and how long they fight is up to the [FightLabRunSettings].
## Side A's rows: each of its profiles once per strategy in [member strategies_a], so strategies compare side by side.

@export var side_a: Array[ActorProfile] = []
@export var side_b: Array[ActorProfile] = []
## How the characters on each side fight, side A's in turn with each; none: the default. Monsters fight as their profile says
@export var strategies_a: Array[FightLabStrategy] = []
@export var strategy_b: FightLabStrategy

var _default_strategy: FightLabStrategy = FightLabStrategy.new()

func get_strategies_a() -> Array[FightLabStrategy]:
	var strategies: Array[FightLabStrategy] = []
	strategies.assign(strategies_a.filter(func(strategy: FightLabStrategy) -> bool: return strategy != null))
	if strategies.is_empty(): strategies.append(_default_strategy)
	return strategies

func get_row_count() -> int: return side_a.size() * get_strategies_a().size()

func get_row_profile(row: int) -> ActorProfile: return side_a[row / get_strategies_a().size()]

func get_row_strategy(row: int) -> FightLabStrategy:
	var strategies: Array[FightLabStrategy] = get_strategies_a()
	return strategies[row % strategies.size()]

## The profile's name, with the strategy's where there are several
func get_row_name(row: int) -> String:
	var profile: ActorProfile = get_row_profile(row)
	var profile_name: String = profile.name if profile else "(empty)"
	return profile_name if get_strategies_a().size() == 1 else "%s · %s" % [profile_name, get_row_strategy(row).get_label()]

## Profiles that can't fight as they are (a character's attributes not rolled yet, as before character creation)
func get_skipped() -> Array[ActorProfile]:
	var skipped: Array[ActorProfile] = []
	skipped.assign((side_a + side_b).filter(func(profile: ActorProfile) -> bool: return not profile or not profile.can_fight()))
	return skipped

## One matchup per pairing across the sides, and per value of [param sweep] if there is one
func get_matchups(sweep: FightLabSweep = null) -> Array[FightLabMatchup]:
	var matchups: Array[FightLabMatchup] = []
	var skipped: Array[ActorProfile] = get_skipped()
	for a_index: int in get_row_count():
		if skipped.has(get_row_profile(a_index)): continue
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

## [param a_index]: a row of side A
func get_matchup(a_index: int, b_index: int) -> FightLabMatchup:
	var matchup: FightLabMatchup = FightLabMatchup.new(get_row_profile(a_index), side_b[b_index])
	matchup.strategy_a = get_row_strategy(a_index)
	matchup.strategy_b = strategy_b if strategy_b else FightLabStrategy.new()
	matchup.a_index = a_index
	matchup.b_index = b_index
	return matchup
