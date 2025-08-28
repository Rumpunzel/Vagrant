@tool
class_name AttributeScoreRoller
extends PanelContainer

signal attribute_score_rolled(attribute: CharacterAttribute, attribute_score: AttributeScore)

@export_group("Configuration")
@export var _icon: TextureRect
@export var _button: Button
@export var _descriptor: Label
@export var _details: RichTextLabel
@export var _color: ColorRect
@export var _score: Label

var attribute: CharacterAttribute :
	set(new_attribute):
		attribute = new_attribute
		_icon.texture = attribute.icon
		_descriptor.text = attribute.descriptor
		_details.text = attribute.details
		_color.color = attribute.color
		tooltip_text = attribute.details

var score: AttributeScore :
	set(new_score):
		score = new_score
		_score.text = "[ %s ] = %d" % [score.get_dice(), score.get_score()]
		if score.get_type() == AttributeScore.Type.DOUBLE: _set_font_colors(Color.GOLD)
		_button.disabled = true

func collapse() -> void:
	pass
	# TODO: animate this
	#_roll.visible = false
	#_details.visible = false

func _set_font_colors(color: Color) -> void:
	_score.add_theme_color_override("font_color", color)
	_score.add_theme_color_override("font_disabled_color", color)
	_score.add_theme_color_override("font_pressed_color", color)
	_score.add_theme_color_override("font_hover_color", color)

func _on_button_pressed() -> void:
	_button.disabled = true
	score = DiceRoller.roll_attribute()
	attribute_score_rolled.emit(attribute, score)
	var next: Control = find_valid_focus_neighbor(SIDE_RIGHT)
	if not next: next = find_valid_focus_neighbor(SIDE_LEFT)
	if next: next.grab_focus()
	focus_mode = Control.FOCUS_NONE
