class_name DiceLogSaveResultEntry
extends DiceLogSaveEntry

func initialize_dice_result(dice_result: DiceRequestResult) -> void:
	var dice_request: DiceRequest = dice_result.get_dice_request()
	var prefix: String = _get_prefix(dice_request.character, dice_request.attribute)
	_entry.type_text("%s: %s" % [prefix, "Rolling..."])

func show_save_result(save_result: SaveResult) -> void:
	var save_request: SaveRequest = save_result.get_dice_request()
	var prefix: String = _get_prefix(save_request.character, save_request.attribute)
	var message: String = "No Breath Dice!"
	if not save_result.get_highest_dice().is_empty():
		var dice_results: String = _get_dice_results(save_result)
		var difficulty: String = _get_highest_result(save_result)
		message = "%s → %s" % [dice_results, difficulty]
	_entry.type_text("%s: %s" % [prefix, message])

func show_fight_result(fight_result: FightResult) -> void:
	var fight_request: FightRequest = fight_result.get_dice_request()
	var prefix: String = _get_prefix(fight_request.character, fight_request.attribute)
	var message: String = "No Breath Dice!"
	## Placeholder
	message = "Fight Result still needs to be implemented..."
	_entry.type_text("%s: %s" % [prefix, message])

func _get_dice_results(dice_result: DiceRequestResult) -> String:
	var dice_results: String = ""
	var highest_dice: Array[Die] = dice_result.get_highest_breath_dice()
	for index: int in highest_dice.size():
		var die: Die = highest_dice[index]
		var color: Color = dice_result.get_die_color(die)
		dice_results += "[color=#%s]%s[/color]" % [color.to_html(), die.die_type]
		if index < highest_dice.size() - 1: dice_results += ", "
	var hint: String = ""
	for die: Die in dice_result.dice:
		hint += "%s" % die
		if die.result > dice_result.get_dice_request().get_attribute_score().get_score(): hint += " ☠"
		if dice_result.get_highest_dice().has(die): hint += " ✔"
		hint += "\n"
	return "[hint=%s]%s[/hint]" % [hint, dice_results]

func _get_highest_result(dice_result: DiceRequestResult) -> String:
	var difficulty: String = "%d" % dice_result.get_highest_result()
	var save_outcome: SaveResult.Outcome = dice_result.get_outcome()
	var color: Color = Color.WHITE
	match save_outcome:
		SaveResult.Outcome.SUCCESS: color = Main.SUCCESS
		SaveResult.Outcome.FAILURE: color= Main.FAILURE
		_: assert(false, "SaveResult.Outcome %s is not supported!" % save_outcome)
	difficulty = "[color=#%s]%s[/color]" % [color.to_html(), difficulty]
	var hint: String = "%s" % [SaveResult.Outcome.find_key(save_outcome)]
	difficulty = "[hint=%s]%s[/hint]" % [hint, difficulty]
	return difficulty
