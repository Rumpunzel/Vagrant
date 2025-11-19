@tool
class_name BreathDieButton
extends DisplayButton

enum IconType {
	NORMAL,
	BLANK,
	FILLED,
}

@export var breath_die: BreathDie :
	set(new_breath_die):
		assert(new_breath_die)
		if breath_die:
			breath_die.state_changed.disconnect(_on_die_state_changed)
		breath_die = new_breath_die
		die_type = breath_die.die_type
		_update()
		breath_die.state_changed.connect(_on_die_state_changed)
@export var die_type: DieType :
	set(new_die_type):
		die_type = new_die_type
		text = ""
		if not die_type:
			icon = null
			return
		match icon_type:
			IconType.NORMAL: icon = die_type.icon
			IconType.BLANK: icon = die_type.icon_blank
			IconType.FILLED: icon = die_type.icon_filled
			_: assert(false, "Does not exist")
@export var icon_type: IconType = IconType.NORMAL

func _update() -> void:
	disabled = not breath_die.alive
	if disabled: tooltip_text = "This die is lost."
	else: tooltip_text = "%s" % breath_die.die_type

func _on_die_state_changed(_alive: bool) -> void:
	_update()
