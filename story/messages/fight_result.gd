@tool
class_name FightResult
extends DiceRequestResult

## The resolved exchange: [member FightExchange.first] is the player, [member FightExchange.second] the opponent
var exchange: FightExchange

func _init(for_dice_request: FightRequest) -> void:
	super(for_dice_request)
	assert(for_dice_request.opponent, "FightRequest needs an opponent")
	exchange = FightExchange.new(for_dice_request.get_plan().roll(dice), for_dice_request.opponent.get_fight_plan().roll())

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
func get_lost_breath_dice() -> Array[Die]: return dice_request.character.get_lost_breath_dice(get_player_side().lost_breath_dice)

func get_die_color(die: Die) -> Color:
	if get_player_side().lost_breath_dice.has(die): return Main.INFO
	if die.result != get_player_side().threat: return Color.WHITE
	match get_outcome():
		Outcome.SUCCESS: return Main.SUCCESS
		Outcome.FAILURE: return Main.FAILURE
	return Main.INFO
