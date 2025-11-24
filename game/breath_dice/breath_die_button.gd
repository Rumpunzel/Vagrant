@tool
class_name BreathDieButton
extends DisplayButton

enum IconType {
	NORMAL,
	BLANK,
	FILLED,
}

@export var die_type: DieType : set = set_die_type
@export var icon_type: IconType = IconType.NORMAL

func _update() -> void:
	if disabled: tooltip_text = "No %s"  % die_type
	else: tooltip_text = "%s breath die" % die_type

func set_die_type(new_die_type: DieType) -> void:
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
	_update()
