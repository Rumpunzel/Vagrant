class_name DiceLogSaveResultEntry
extends DiceLogSaveEntry

@export_range(0.0, 5.0) var _reveal_delay: float = 1.5
@export var _delay_message: String = "Rolling..."

@export_group("Configuration")
@export var _update_delay_timer: Timer

func initialize_save_result(save_result: SaveResult) -> void:
	var save_request: SaveRequest = save_result.save_request
	var prefix: String = _get_prefix(save_request.character, save_request.attribute)
	var message: String = "No Breath Dice!"
	if not save_result.get_highest_dice().is_empty():
		var dice_results: String = _get_dice_results(save_result)
		var difficulty: String = _get_difficulty(save_result)
		message = "%s → %s" % [dice_results, difficulty]
	if is_inside_tree():
		_entry.type_text("%s: %s" % [prefix, _delay_message])
		_update_delay_timer.start(_reveal_delay)
		await _update_delay_timer.timeout
	_entry.type_text("%s: %s" % [prefix, message])

func initialize_fight_result(fight_result: FightResult) -> void:
	var fight_request: FightRequest = fight_result.fight_request
	var prefix: String = _get_prefix(fight_request.character, fight_request.attribute)
	var message: String = "No Breath Dice!"
	if is_inside_tree():
		_entry.type_text("%s: %s" % [prefix, _delay_message])
		_update_delay_timer.start(_reveal_delay)
		await _update_delay_timer.timeout
	_entry.type_text("%s: %s" % [prefix, message])

func _get_dice_results(save_result: SaveResult) -> String:
	var dice_results: String = ""
	var highest_dice: Array[BreathDie] = save_result.get_highest_breath_dice()
	for index: int in highest_dice.size():
		var die: BreathDie = highest_dice[index]
		var color: Color = save_result.get_die_color(die)
		dice_results += "[color=#%s]%s[/color]" % [color.to_html(), die.die_type]
		if index < highest_dice.size() - 1: dice_results += ", "
	var hint: String = ""
	for die: BreathDie in save_result.dice:
		hint += "%s" % die
		if not die.alive: hint += " ☠"
		if save_result.get_highest_dice().has(die): hint += " ✔"
		hint += "\n"
	return "[hint=%s]%s[/hint]" % [hint, dice_results]

func _get_difficulty(save_result: SaveResult) -> String:
	var difficulty: String = "%d" % save_result.get_highest_result()
	var save_outcome: SaveResult.Outcome = save_result.get_save_outcome()
	var color: Color = Color.WHITE
	match save_outcome:
		SaveResult.Outcome.SUCCESS: color = Color.LIME_GREEN
		SaveResult.Outcome.FAILURE: color= Color.FIREBRICK
		_: assert(false, "SaveResult.Outcome %s is not supported!" % save_outcome)
	difficulty = "[color=#%s]%s[/color]" % [color.to_html(), difficulty]
	var hint: String = "Difficulty: %d → %s" % [save_result.save_request.get_difficulty(), SaveResult.Outcome.find_key(save_outcome)]
	difficulty = "[hint=%s]%s[/hint]" % [hint, difficulty]
	return difficulty
