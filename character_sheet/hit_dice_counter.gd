extends Button

func update_counter(new_count: int) -> void:
	if new_count <= 0:
		text = "-"
		disabled = true
	else:
		text = "%d" % new_count
		disabled = false
