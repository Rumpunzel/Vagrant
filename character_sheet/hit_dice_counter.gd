extends SpinBox

func update_counter(new_count: int) -> void:
	value = new_count
	editable = new_count > 0
