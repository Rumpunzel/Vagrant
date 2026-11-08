@tool
class_name BreathDieButton
extends DisplayButton

enum IconType {
	NORMAL,
	BLANK,
	FILLED,
}

const RULE: String = "Rolled for saves and fights. Lost if it comes up above the attribute it was rolled with."
const RECOVERY: String = "Catching your breath recovers lost dice of all but the type it exhausts."

@export var die_type: DieType : set = set_die_type
@export var icon_type: IconType = IconType.NORMAL

## Whichever subclass: they keep [method _update] for themselves. [member Control.tooltip_text] if set
func _get_tooltip(_at_position: Vector2) -> String:
	if not tooltip_text.is_empty() or not die_type: return tooltip_text
	if disabled: return TooltipText.compose("Lost %s" % die_type, RECOVERY)
	return TooltipText.compose("%s breath die" % die_type, RULE)

func _make_custom_tooltip(for_text: String) -> Object: return TooltipText.make_label(for_text, self)

func _update() -> void: pass

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
