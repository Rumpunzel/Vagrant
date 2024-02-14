class_name DiceLogEntry
extends RichTextLabel

func initialize_die_result(die_result: DiceRoller.DieResult) -> void:
	append_text("d%d: %d, " % [die_result.die, die_result.result])

func initialize_save_result(save_result: DiceRoller.SaveResult) -> void:
	var dice_results := ""
	for index in save_result.dice.size():
		var dice_result := save_result.dice[index]
		dice_results += "d%d → %d" % [dice_result.die, dice_result.result]
		if dice_result.outcome == DiceRoller.DieOutcome.EXHAUSTED: dice_results += " ☠"
		if dice_result == save_result.result: dice_results += " ✓"
		dice_results += "\n"
	
	var difficulty := ""
	if save_result.difficulty != DiceRoller.SaveOutcome.NORMAL:
		difficulty += "Difficulty: %d → %s" % [save_result.difficulty, DiceRoller.SaveOutcome.find_key(save_result.get_save_outcome())]
	
	if not dice_results.is_empty() or not difficulty.is_empty(): push_hint(dice_results + difficulty)
	append_text("[%s] %s: " % [Character.Attributes.find_key(save_result.attribute), save_result.character.name])
	
	if save_result.result != null:
		match save_result.result.outcome:
			DiceRoller.DieOutcome.NORMAL:
				push_color(Color.WHITE)
			DiceRoller.DieOutcome.EXHAUSTED:
				push_color(Color.FIREBRICK)
		append_text("d%d" % save_result.result.die)
		pop()
		append_text(" → ")
		match save_result.get_save_outcome():
			DiceRoller.SaveOutcome.NORMAL:
				push_color(Color.WHITE)
			DiceRoller.SaveOutcome.SUCCESS:
				push_color(Color.LIME_GREEN)
			DiceRoller.SaveOutcome.FAILURE:
				push_color(Color.FIREBRICK)
		append_text("%d" % save_result.result.result)
		pop()
	else:
		append_text("No Hit Dice!")
	if not dice_results.is_empty(): pop()
