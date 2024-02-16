extends SpinBox

@export var _die_type: DieType

func update_hit_dice(available_hit_dice: int, max_hit_dice: int = 0) -> void:
	max_value = max_hit_dice if max_hit_dice > 0 else available_hit_dice
	suffix = "/ %d%s" % [available_hit_dice, _die_type]
	value = available_hit_dice
	editable = available_hit_dice > 0
