@tool
class_name FightResult
extends DiceRequestResult

## The resolved exchange: [member FightExchange.first] is the player, [member FightExchange.second] the opponent
var exchange: FightExchange
## Weapon the opponent fought with this exchange (null if natural or unarmed)
var opponent_weapon: Weapon
var player_shield: Shield
var opponent_shield: Shield

func _init(for_dice_request: FightRequest) -> void:
	super(for_dice_request)
	assert(for_dice_request.opponent, "FightRequest needs an opponent")
	exchange = FightExchange.new(_create_player_side(), _create_opponent_side())

func get_dice_request() -> FightRequest: return dice_request
func get_player_side() -> FightSide: return exchange.first
func get_opponent_side() -> FightSide: return exchange.second

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
	side.abilities = fight_request.character.character_profile.get_abilities()
	var extra_weapon_dice: int = 0
	for ability: Ability in side.abilities: extra_weapon_dice += ability.get_extra_weapon_dice()
	_arm(side, fight_request.selected_weapon, extra_weapon_dice)
	_armor(side, fight_request.character.armor)
	player_shield = Shield.get_first_usable(fight_request.character.shields)
	_raise(side, player_shield)
	return side

func _create_opponent_side() -> FightSide:
	var opponent: Monster = get_dice_request().opponent
	var breath_dice: Array[Die] = DiceRoller.roll_dice(opponent.get_breath_dice_pool())
	var scores: Dictionary[CharacterAttribute, int] = {}
	for attribute: CharacterAttribute in Rules.ATTRIBUTES: scores[attribute] = opponent.get_score(attribute)
	var side: FightSide = FightSide.new(opponent.get_attack().get_stance(), breath_dice, scores, [], false, opponent.get_attack().get_nerves_target())
	if opponent.has_natural_weapons():
		side.weapon_dice = breath_dice
		side.has_natural_weapons = true
	else:
		opponent_weapon = opponent.get_weapon()
		_arm(side, opponent_weapon)
	_armor(side, opponent.armor)
	side.weapon_tactic = opponent.monster_profile.weapon_tactic
	side.shield_tactic = opponent.monster_profile.shield_tactic
	side.armor_tactic = opponent.monster_profile.armor_tactic
	opponent_shield = Shield.get_first_usable(opponent.shields)
	_raise(side, opponent_shield)
	return side

## Rolls the shield's die with the others; whether it is raised is decided in the exchange
func _raise(side: FightSide, shield: Shield) -> void:
	if not shield: return
	var shield_die: Die = shield.get_die_type().get_die()
	DiceRoller.roll_die(shield_die)
	side.shield_dice = [shield_die] as Array[Die]
	side.shield_wield_attribute = shield.get_wield_attribute()
	side.shield_marked_faces = shield.marked_faces.duplicate()

func _armor(side: FightSide, armor: Array[Armor]) -> void:
	side.armor_blocks = Armor.get_blocked_results(armor)
	side.damage_reduction = Armor.get_total_damage_reduction(armor)

func _arm(side: FightSide, weapon: Weapon, extra_dice: int = 0) -> void:
	if not weapon: return
	var weapon_dice: Array[Die] = []
	for _index: int in 1 + extra_dice:
		var weapon_die: Die = weapon.get_die_type().get_die()
		DiceRoller.roll_die(weapon_die)
		weapon_dice.append(weapon_die)
	side.weapon_dice = weapon_dice
	side.wield_attribute = weapon.get_wield_attribute()
	side.marked_faces = weapon.marked_faces.duplicate()
