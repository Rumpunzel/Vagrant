class_name IncapacitationStep
extends ExchangeStep

## After an injury that overwhelms, a Guts save against all injuries. Monsters roll all their breath dice right away;
## the player's save is shown by whoever presents the exchange, who hands its outcome to [method resolve].

func applies(fight: Fight) -> bool: return get_side(fight).injury_taken > 0 and _is_overwhelmed(fight) and _can_continue(fight)

func enter(fight: Fight) -> String:
	return "" if is_player() else _resist_as_monster(fight)

func get_difficulty(fight: Fight) -> int:
	return get_actor(fight).get_injury_total()

## The player's save; returns the line telling the outcome, which also joins the exchange summary
func resolve(fight: Fight, success: bool) -> String:
	assert(is_player())
	fight.player_incapacitated = not success
	var line: String = "You keep your senses." if success else "Everything goes dark."
	fight.tell(line)
	return line

func _is_overwhelmed(fight: Fight) -> bool:
	return get_actor(fight).is_overwhelmed_by_injuries()

func _can_continue(fight: Fight) -> bool:
	return not get_actor(fight).is_out_of_breath()

func _resist_as_monster(fight: Fight) -> String:
	var monster: Monster = fight.monster
	var difficulty: int = get_difficulty(fight)
	var dice: Array[Die] = fight.roll_dice.call(monster.get_breath_dice_pool())
	var highest: int = FightExchange.get_highest_result(dice)
	var guts: int = monster.get_score(Rules.STRENGTH)
	var lost: Array[Die] = []
	lost.assign(dice.filter(func(die: Die) -> bool: return die.result > guts))
	monster.lose_breath_dice(lost)
	fight.monster_incapacitated = highest < difficulty
	return "The %s can barely stand: %s save against %d — %d. %s" % [
		monster.get_monster_name(), Fight.describe_attribute(Rules.STRENGTH), difficulty, highest,
		"It collapses." if fight.monster_incapacitated else "It keeps its feet.",
	]
