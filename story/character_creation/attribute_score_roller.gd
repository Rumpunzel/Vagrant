@tool
class_name AttributeScoreRoller
extends PanelContainer

signal attribute_score_rolled(attribute: CharacterAttribute, attribute_score: BaseAttributeScore)

@export_group("Configuration")
@export var _icon: TextureRect
@export var _button: Button
@export var _descriptor: Label
@export var _details: RichTextLabel
@export var _color: ColorRect
@export var _score: RichTextLabel

var attribute: CharacterAttribute :
	set(new_attribute):
		attribute = new_attribute
		_icon.texture = attribute.icon
		_descriptor.text = attribute.descriptor
		_details.text = attribute.details
		_color.color = attribute.color
		tooltip_text = attribute.details

var score: BaseAttributeScore :
	set(new_score):
		score = new_score
		_button.disabled = true  
		update()

var modifiers: Array[AttributeScore.Modifier] = [] :
	set(new_modifiers):
		modifiers = new_modifiers
		update()

func _ready() -> void:
	if not get_viewport().gui_get_focus_owner(): _button.grab_focus()

func update() -> void:
	var attribute_score: AttributeScore = _get_attribute_score()
	_score.text = "%s = %d" % [attribute_score.get_details(), attribute_score.get_score()]

func _get_attribute_score() -> AttributeScore:
	return AttributeScore.create_with_modifiers(attribute, score, modifiers)

func _on_button_pressed() -> void:
	_button.disabled = true
	_button.focus_mode = Control.FOCUS_NONE
	score = DiceRoller.roll_attribute()
	attribute_score_rolled.emit(attribute, score)
	var next: Control = find_valid_focus_neighbor(SIDE_RIGHT)
	if not next: next = find_valid_focus_neighbor(SIDE_LEFT)
	if next: next.grab_focus()
