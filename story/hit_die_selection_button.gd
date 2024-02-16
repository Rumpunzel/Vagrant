class_name HitDieSelectionButton
extends Button

var die: Die :
	set(new_die):
		if die != null: die.rolled.disconnect(_update_button)
		die = new_die
		_update_button(die)
		die.rolled.connect(_update_button)

func _update_button(_die: Die) -> void:
	icon = die.die_type.icon
	disabled = die.status == Die.Status.EXHAUSTED
