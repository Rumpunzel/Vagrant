class_name DiceLogEntry
extends PanelContainer

@export_group("Configuration")
@export var _entry: TypingLabel

func initialize_die_result(die: Die) -> void:
	_entry.type_text("%s" % die)

func initialize_save_request(save_request: SaveRequest) -> void:
	var attribute_prefix: String = _get_attribute_prefix(save_request.character, save_request.attribute)
	_entry.type_text("%s: Choose Hit Dice…" % attribute_prefix)

func initialize_save_result(save_result: SaveResult) -> void:
	var attribute_prefix: String = _get_attribute_prefix(save_result.character, save_result.attribute)
	var message: String = "No Hit Dice!"
	if not save_result.highest_dice.is_empty():
		var dice_results: String = _get_dice_results(save_result)
		var difficulty: String = _get_difficulty(save_result)
		message = "%s → %s" % [dice_results, difficulty]
	_entry.type_text("%s: %s" % [attribute_prefix, message])

func _get_attribute_prefix(character: Character, attribute: CharacterAttribute) -> String:
	var hint: String = "%s: %d" % [attribute, character.get_attribute_score(attribute).get_score()]
	return "[hint=%s][%s][/hint]" % [hint, attribute]

func _get_dice_results(save_result: SaveResult) -> String:
	var dice_results: String = ""
	var highest_dice: Array[Die] = save_result.highest_dice
	for index: int in highest_dice.size():
		var die: Die = highest_dice[index]
		var color: Color = die.get_die_color(save_result.difficulty)
		dice_results += "[color=#%s]%s[/color]" % [color.to_html(), die.die_type]
		if index < highest_dice.size() - 1: dice_results += ", "
	var hint: String = ""
	for die: Die in save_result.dice:
		hint += "%s" % die
		if not die.is_alive(): hint += " ☠"
		if save_result.highest_dice.has(die): hint += " ✔"
		hint += "\n"
	return "[hint=%s]%s[/hint]" % [hint, dice_results]

func _get_difficulty(save_result: SaveResult) -> String:
	var difficulty: String = "%d" % save_result.result
	var color: Color = Color.WHITE
	match save_result.save_outcome:
		SaveResult.Outcome.NORMAL: pass
		SaveResult.Outcome.SUCCESS: color = Color.LIME_GREEN
		SaveResult.Outcome.FAILURE: color= Color.FIREBRICK
	if color != Color.WHITE:
		difficulty = "[color=#%s]%s[/color]" % [color.to_html(), difficulty]
	if save_result.difficulty != SaveResult.Outcome.NORMAL:
		var hint: String = "Difficulty: %d → %s" % [save_result.difficulty, SaveResult.Outcome.find_key(save_result.save_outcome)]
		difficulty = "[hint=%s]%s[/hint]" % [hint, difficulty]
	return difficulty
