@tool
class_name AttributeScoreRoller
extends PanelContainer

signal attribute_score_rolled(attribute_score: AttributeScore)

@export_group("Configuration")
@export var _color: ColorRect
@export var _descriptor: Label
@export var _score: Label
@export var _roll: Button

var attribute: CharacterAttribute :
	set(new_attribute):
		attribute = new_attribute
		_color.color = attribute.color
		_roll.icon = attribute.icon
		_descriptor.text = attribute.descriptor

var score: AttributeScore :
	set(new_score):
		score = new_score
		_score.text = "[ %s ] = %d" % [score.get_dice(), score.get_score()]
		if score.get_type() == AttributeScore.Type.DOUBLE: _set_font_colors(Color.GOLD)
		_roll.disabled = true

func _set_font_colors(color: Color) -> void:
	_score.add_theme_color_override("font_color", color)
	_score.add_theme_color_override("font_disabled_color", color)
	_score.add_theme_color_override("font_pressed_color", color)
	_score.add_theme_color_override("font_hover_color", color)

func _on_roll_pressed() -> void:
	score = DiceRoller.roll_attribute()
	attribute_score_rolled.emit(score)
