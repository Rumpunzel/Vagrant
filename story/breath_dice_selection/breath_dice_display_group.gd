@tool
class_name BreathDiceDisplayGroup
extends BreathDiceGroup

func _ready() -> void:
	die_type_changed.connect(_on_die_type_changed)
	breath_die_button_added.connect(_on_breath_die_button_added)

func _on_breath_die_button_added(breath_die_button: BreathDieButton) -> void:
	var stack_color: Color = Color.WHITE * pow(0.5, get_elements().size() - 1)
	stack_color.a = 1.0
	breath_die_button.self_modulate = stack_color
	_update_tooltip()

func _update_tooltip() -> void:
	tooltip_text = "%d%s" % [get_elements().size(), die_type]

func _on_die_type_changed(_die_type: DieType) -> void:
	_update_tooltip()
