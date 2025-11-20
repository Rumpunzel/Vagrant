@tool
class_name BreathDiceDisplayGroup
extends BreathDiceGroup

var _exhaustion: Array[DieType] :
	set(new_exhaustion):
		_exhaustion = new_exhaustion
		_update_visibility()

func _ready() -> void:
	die_type_changed.connect(_on_die_type_changed)
	breath_die_button_added.connect(_on_breath_die_button_added)

func is_exhausted() -> bool: return _exhaustion.has(die_type)

func set_exhaustion(exhaustion: Array[DieType]) -> void:
	_exhaustion = exhaustion

func set_breath_dice(new_breath_dice: Array[BreathDie]) -> void:
	super.set_breath_dice(new_breath_dice)
	_update_visibility()

func _update_visibility() -> void:
	modulate = Main.FAILURE if is_exhausted() else Color.WHITE
	modulate.a = 0.0 if is_exhausted() and breath_dice.is_empty() else 1.0

func _update_tooltip() -> void:
	tooltip_text = "%d%s" % [get_elements().size(), die_type]

func _on_breath_die_button_added(breath_die_button: BreathDieButton) -> void:
	var stack_color: Color = Color.WHITE * pow(0.5, get_elements().size() - 1)
	stack_color.a = 1.0
	breath_die_button.self_modulate = stack_color
	_update_visibility()
	_update_tooltip()

func _on_die_type_changed(_die_type: DieType) -> void:
	_update_tooltip()
