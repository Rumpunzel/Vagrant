class_name DiceLogEntry
extends PanelContainer

func initialize_die_result(die: Die) -> void:
	%Entry.clear()
	%Entry.append_text("%s" % die)

func initialize_save_result(save_result: DiceRoller.SaveResult) -> void:
	var character := save_result.character
	var attribute := save_result.attribute
	%Entry.clear()
	%Entry.push_hint("%s: %d" % [attribute, character.get_attribute_score(attribute)])
	%Entry.append_text("[%s]:" % attribute)
	%Entry.pop()
	%Entry.append_text(" ")
	if save_result.highest_die == null:
		%Entry.append_text("No Hit Dice!")
		return
	
	var dice_results := ""
	for die: Die in save_result.dice:
		dice_results += "%s" % die
		if die.status == Die.Status.EXHAUSTED: dice_results += " ☠"
		if die.result == save_result.highest_die.result: dice_results += " ✓"
		dice_results += "\n"
	%Entry.push_hint(dice_results)
	match save_result.highest_die.status:
		Die.Status.ALIVE:
			%Entry.push_color(Color.WHITE)
		Die.Status.EXHAUSTED:
			%Entry.push_color(Color.FIREBRICK)
	%Entry.append_text("%s" % save_result.highest_die.die_type)
	%Entry.pop()
	%Entry.pop()
	
	%Entry.append_text(" → ")
	
	var difficulty := ""
	if save_result.difficulty != DiceRoller.SaveOutcome.NORMAL:
		difficulty += "Difficulty: %d → %s" % [save_result.difficulty, DiceRoller.SaveOutcome.find_key(save_result.save_outcome)]
	%Entry.push_hint(difficulty)
	match save_result.save_outcome:
		DiceRoller.SaveOutcome.NORMAL:
			%Entry.push_color(Color.WHITE)
		DiceRoller.SaveOutcome.SUCCESS:
			%Entry.push_color(Color.LIME_GREEN)
		DiceRoller.SaveOutcome.FAILURE:
			%Entry.push_color(Color.FIREBRICK)
	%Entry.append_text("%d" % save_result.highest_die.result)
	%Entry.pop()
	%Entry.pop()
