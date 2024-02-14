extends SpinBox

func update_dice_amount(available_hit_dice: int) -> void:
	max_value = available_hit_dice
	suffix = "/ %d" % available_hit_dice
	value = available_hit_dice
	editable = available_hit_dice > 0
