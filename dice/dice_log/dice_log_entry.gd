class_name DiceLogEntry
extends PanelContainer

@export_group("Configuration")
@export var _entry: RichTextLabel

func initialize_die_result(die: Die) -> void:
	_entry.clear()
	_entry.append_text("%s" % die)

func initialize_save_request(save_request: SaveRequest) -> void:
	var character := save_request.character
	var attribute := save_request.attribute
	_entry.clear()
	_append_attribute_prefix(character, attribute)
	_entry.append_text(" ")
	_entry.append_text(" Choose Hit Dice to roll…")

func initialize_save_result(save_result: SaveResult) -> void:
	var character := save_result.character
	var attribute := save_result.attribute
	_entry.clear()
	_append_attribute_prefix(character, attribute)
	_entry.append_text(" ")
	if save_result.highest_dice.is_empty():
		_entry.append_text("No Hit Dice!")
		return
	
	var dice_results := ""
	for die: Die in save_result.dice:
		dice_results += "%s" % die
		if not die.is_alive(): dice_results += " ☠"
		if save_result.highest_dice.has(die): dice_results += " ✓"
		dice_results += "\n"
	_entry.push_hint(dice_results)
	_entry.append_text("[")
	var highest_dice := save_result.highest_dice
	for index: int in highest_dice.size():
		var die: Die = highest_dice[index]
		_entry.push_color(die.get_die_color(save_result.difficulty))
		_entry.append_text("%s" % [die.die_type])
		_entry.pop()
		if index < highest_dice.size() - 1: _entry.append_text(", ")
	_entry.append_text("]")
	_entry.pop()
	
	_entry.append_text(" → ")
	
	var difficulty := ""
	if save_result.difficulty != SaveResult.Outcome.NORMAL:
		difficulty += "Difficulty: %d → %s" % [save_result.difficulty, SaveResult.Outcome.find_key(save_result.save_outcome)]
	_entry.push_hint(difficulty)
	match save_result.save_outcome:
		SaveResult.Outcome.NORMAL:
			_entry.push_color(Color.WHITE)
		SaveResult.Outcome.SUCCESS:
			_entry.push_color(Color.LIME_GREEN)
		SaveResult.Outcome.FAILURE:
			_entry.push_color(Color.FIREBRICK)
	_entry.append_text("%d" % save_result.result)
	_entry.pop()
	_entry.pop()

func _append_attribute_prefix(character: Character, attribute: CharacterAttribute) -> void:
	_entry.push_hint("%s: %d" % [attribute, character.get_attribute_score(attribute)])
	_entry.append_text("[%s]:" % attribute)
	_entry.pop()
