class_name DiceLogSaveResultEntry
extends DiceLogSaveEntry

func initialize_save_result(save_result: SaveResult, character_resolver: Callable) -> void:
	var save_request: SaveRequest = save_result.save_request
	var character: Character = character_resolver.call(save_request.character_profile)
	var attribute_prefix: String = _get_attribute_prefix(character, save_request.attribute)
	var message: String = "No Breath Dice!"
	if not save_result.get_highest_dice().is_empty():
		var dice_results: String = _get_dice_results(save_result)
		var difficulty: String = _get_difficulty(save_result)
		message = "%s → %s" % [dice_results, difficulty]
	_entry.type_text("%s: %s" % [attribute_prefix, message])

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
		if not die.is_alive(): hint += " ☠"
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
	var hint: String = "Difficulty: %d → %s" % [save_result.save_request.difficulty, SaveResult.Outcome.find_key(save_outcome)]
	difficulty = "[hint=%s]%s[/hint]" % [hint, difficulty]
	return difficulty
