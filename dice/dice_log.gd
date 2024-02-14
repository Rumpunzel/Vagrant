extends RichTextLabel

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	DiceRoller.save_rolled.connect(_on_save_rolled)

func _exit_tree() -> void:
	DiceRoller.save_rolled.disconnect(_on_save_rolled)

func _on_die_rolled(dice_result: DiceRoller.DieResult) -> void:
	append_text("d%d: %d, " % [dice_result.die, dice_result.result])

func _on_save_rolled(dice_log_entry: DiceRoller.DiceLogEntry) -> void:
	var dice_results := ""
	for index in dice_log_entry.dice.size():
		var dice_result := dice_log_entry.dice[index]
		dice_results += "d%d → %d" % [dice_result.die, dice_result.result]
		if dice_result.outcome == DiceRoller.DieOutcome.EXHAUSTED: dice_results += " ☠"
		if dice_result == dice_log_entry.result: dice_results += " ✓"
		dice_results += "\n"
	
	var difficulty := ""
	if dice_log_entry.difficulty != DiceRoller.SaveOutcome.NORMAL:
		difficulty += "Difficulty: %d → %s" % [dice_log_entry.difficulty, DiceRoller.SaveOutcome.find_key(dice_log_entry.get_save_outcome())]
	
	if not dice_results.is_empty() or not difficulty.is_empty(): push_hint(dice_results + difficulty)
	append_text("[%s] %s: " % [Character.Attributes.find_key(dice_log_entry.attribute), dice_log_entry.character.name])
	
	if dice_log_entry.result != null:
		match dice_log_entry.result.outcome:
			DiceRoller.DieOutcome.NORMAL:
				push_color(Color.WHITE)
			DiceRoller.DieOutcome.EXHAUSTED:
				push_color(Color.FIREBRICK)
		append_text("d%d" % dice_log_entry.result.die)
		pop()
		append_text(" → ")
		match dice_log_entry.get_save_outcome():
			DiceRoller.SaveOutcome.NORMAL:
				push_color(Color.WHITE)
			DiceRoller.SaveOutcome.SUCCESS:
				push_color(Color.LIME_GREEN)
			DiceRoller.SaveOutcome.FAILURE:
				push_color(Color.FIREBRICK)
		append_text("%d" % dice_log_entry.result.result)
		pop()
	else:
		append_text("No Hit Dice!")
	if not dice_results.is_empty(): pop()
	append_text("\n")
