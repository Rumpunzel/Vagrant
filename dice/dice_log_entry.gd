class_name DiceLogEntry
extends PanelContainer

func initialize_die_result(die_result: DiceRoller.DieResult) -> void:
	%Entry.clear()
	%Entry.append_text("d%d: %d, " % [die_result.die, die_result.result])

func initialize_save_result(save_result: DiceRoller.SaveResult) -> void:
	var character := save_result.character
	var attribute := save_result.attribute
	
	%Entry.clear()
	%Entry.push_hint("%s: %d" % [attribute, character.get_attribute_score(attribute)])
	%Entry.append_text("[%s]:" % attribute)
	%Entry.pop()
	%Entry.append_text(" ")
	
	if save_result.result != null:
		var dice_results := ""
		for index in save_result.dice.size():
			var dice_result := save_result.dice[index]
			dice_results += "d%d → %d" % [dice_result.die, dice_result.result]
			if dice_result.outcome == DiceRoller.DieOutcome.EXHAUSTED: dice_results += " ☠"
			if dice_result == save_result.result: dice_results += " ✓"
			dice_results += "\n"
		%Entry.push_hint(dice_results)
		match save_result.result.outcome:
			DiceRoller.DieOutcome.NORMAL:
				%Entry.push_color(Color.WHITE)
			DiceRoller.DieOutcome.EXHAUSTED:
				%Entry.push_color(Color.FIREBRICK)
		%Entry.append_text("d%d" % save_result.result.die)
		%Entry.pop()
		%Entry.pop()
		
		%Entry.append_text(" → ")
		
		var difficulty := ""
		if save_result.difficulty != DiceRoller.SaveOutcome.NORMAL:
			difficulty += "Difficulty: %d → %s" % [save_result.difficulty, DiceRoller.SaveOutcome.find_key(save_result.get_save_outcome())]
		%Entry.push_hint(difficulty)
		match save_result.get_save_outcome():
			DiceRoller.SaveOutcome.NORMAL:
				%Entry.push_color(Color.WHITE)
			DiceRoller.SaveOutcome.SUCCESS:
				%Entry.push_color(Color.LIME_GREEN)
			DiceRoller.SaveOutcome.FAILURE:
				%Entry.push_color(Color.FIREBRICK)
		%Entry.append_text("%d" % save_result.result.result)
		%Entry.pop()
		%Entry.pop()
	else:
		%Entry.append_text("No Hit Dice!")
