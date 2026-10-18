@tool
class_name FightResult
extends DiceRequestResult

## The resolved exchange: [member FightExchange.first] is the player, [member FightExchange.second] the opponent
var exchange: FightExchange
## Weapon the opponent fought with this exchange (null if natural or unarmed)
var opponent_weapon: Weapon

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
	var scores: Dictionary[CharacterAttribute, int] = {}
	for attribute: CharacterAttribute in Rules.ATTRIBUTES: scores[attribute] = fight_request.character.get_attribute_score(attribute).get_score()
	var side: FightSide = FightSide.new(fight_request.attribute, dice, scores, [], fight_request.fleeing, fight_request.nerves_target)
	_arm(side, fight_request.selected_weapon)
	return side

func _create_opponent_side() -> FightSide:
	var opponent: Monster = get_dice_request().opponent
	var breath_dice: Array[Die] = DiceRoller.roll_dice(opponent.get_breath_dice_pool())
	var scores: Dictionary[CharacterAttribute, int] = {}
	for attribute: CharacterAttribute in Rules.ATTRIBUTES: scores[attribute] = opponent.get_score(attribute)
	var side: FightSide = FightSide.new(opponent.get_nature(), breath_dice, scores)
	if opponent.has_natural_weapons():
		side.weapon_dice = breath_dice
		side.has_natural_weapons = true
	else:
		opponent_weapon = opponent.get_weapon()
		_arm(side, opponent_weapon)
	return side

## Rolls [param weapon]'s die for [param side]; no weapon = unarmed
func _arm(side: FightSide, weapon: Weapon) -> void:
	if not weapon: return
	var weapon_die: Die = weapon.get_die_type().get_die()
	DiceRoller.roll_die(weapon_die)
	side.weapon_dice = [weapon_die] as Array[Die]
	side.wield_attribute = weapon.get_wield_attribute()
	side.marked_faces = weapon.marked_faces.duplicate()
