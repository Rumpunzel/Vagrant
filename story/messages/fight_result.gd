@tool
class_name FightResult
extends DiceRequestResult

## The resolved exchange: [member FightExchange.first] is the player, [member FightExchange.second] the opponent
var exchange: FightExchange

func _init(for_dice_request: FightRequest) -> void:
	super(for_dice_request)
	assert(for_dice_request.opponent, "FightRequest needs an opponent")
	exchange = FightExchange.new(_create_player_side(), _create_opponent_side())

func get_dice_request() -> FightRequest: return dice_request
func get_player_side() -> FightSide: return exchange.first
func get_opponent_side() -> FightSide: return exchange.second

## Compares threats; on a tie both sides get their full threat as margin
func get_outcome() -> Outcome:
	var difference: int = get_player_side().threat - get_opponent_side().threat
	if difference > 0: return Outcome.SUCCESS
	if difference < 0: return Outcome.FAILURE
	return Outcome.DRAW

func get_margin() -> int: return abs(get_player_side().threat - get_opponent_side().threat)

## Losses come from the exchange (stance, flee and Nerves already applied), then origins may change them
func get_lost_breath_dice() -> Array[Die]:
	var lost_breath_dice: Array[Die] = get_player_side().lost_breath_dice.duplicate()
	for origin: Origin in dice_request.character.character_profile.origins:
		lost_breath_dice = origin.get_lost_breath_dice(lost_breath_dice)
	return lost_breath_dice

func get_die_color(die: Die) -> Color:
	if get_player_side().lost_breath_dice.has(die): return Main.INFO
	if die.result != get_player_side().threat: return Color.WHITE
	match get_outcome():
		Outcome.SUCCESS: return Main.SUCCESS
		Outcome.FAILURE: return Main.FAILURE
	return Main.INFO

func _create_player_side() -> FightSide:
	var fight_request: FightRequest = get_dice_request()
	var weapon_dice: Array[Die] = []
	for weapon_die: WeaponDie in fight_request.selected_weapon_dice:
		weapon_die.roll()
		weapon_dice.append(weapon_die)
	var scores: Dictionary[CharacterAttribute, int] = {}
	for attribute: CharacterAttribute in Rules.ATTRIBUTES: scores[attribute] = fight_request.character.get_attribute_score(attribute).get_score()
	return FightSide.new(fight_request.attribute, dice, scores, weapon_dice, fight_request.fleeing, fight_request.nerves_target)

func _create_opponent_side() -> FightSide:
	var opponent: Monster = get_dice_request().opponent
	var breath_dice: Array[Die] = DiceRoller.roll_dice(opponent.get_breath_dice_pool())
	var weapon_dice: Array[Die] = []
	weapon_dice.assign(opponent.get_weapon_dice())
	DiceRoller.roll_dice(weapon_dice)
	var scores: Dictionary[CharacterAttribute, int] = {}
	for attribute: CharacterAttribute in Rules.ATTRIBUTES: scores[attribute] = opponent.get_score(attribute)
	return FightSide.new(opponent.get_nature(), breath_dice, scores, weapon_dice)
