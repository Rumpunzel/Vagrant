class_name IncapacitationStep
extends ExchangeStep

## After an injury that overwhelms, a Guts save against all injuries. An actor that decides by itself rolls all its breath dice
## right away; the player's save is shown by whoever presents the exchange, who hands its outcome to [method resolve].

func applies(fight: Fight) -> bool: return get_side(fight).injury_taken > 0 and _is_overwhelmed(fight) and _can_continue(fight)

func enter(fight: Fight) -> String:
	return "" if is_player(fight) else _resist(fight)

func get_difficulty(fight: Fight) -> int:
	return get_actor(fight).get_injury_total()

## The player's save; returns the line telling the outcome, which also joins the exchange summary
func resolve(fight: Fight, success: bool) -> String:
	assert(is_player(fight))
	fight.incapacitated[get_actor(fight)] = not success
	var line: String = "You keep your senses." if success else "Everything goes dark."
	fight.tell(line)
	return line

func _is_overwhelmed(fight: Fight) -> bool:
	return get_actor(fight).is_overwhelmed_by_injuries()

func _can_continue(fight: Fight) -> bool:
	return not get_actor(fight).is_out_of_breath()

## All breath dice against the injuries; those above Guts are lost
func _resist(fight: Fight) -> String:
	var actor: Actor = get_actor(fight)
	var difficulty: int = get_difficulty(fight)
	var dice: Array[Die] = fight.roll_dice.call(actor.get_breath_dice_pool())
	var highest: int = FightExchange.get_highest_result(dice)
	var guts: int = actor.get_score(Rules.STRENGTH)
	var lost: Array[Die] = []
	lost.assign(dice.filter(func(die: Die) -> bool: return die.result > guts))
	actor.lose_breath_dice(lost)
	var collapses: bool = highest < difficulty
	fight.incapacitated[actor] = collapses
	if collapses and actor is Monster: (actor as Monster).incapacitated = true
	return "%s can barely stand: %s save against %d — %d. %s" % [
		get_subject(fight), Fight.describe_attribute(Rules.STRENGTH), difficulty, highest,
		"%s collapses." % ("It" if actor is Monster else get_subject(fight)) if collapses else "%s keeps %s feet." % ["It" if actor is Monster else get_subject(fight), get_pronoun(fight)],
	]
