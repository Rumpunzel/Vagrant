class_name DiceLogDieEntry
extends DiceLogEntry

func initialize_die_result(die: Die) -> void:
	_entry.type_text("%s" % die)
