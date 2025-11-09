@tool
class_name StanceSelection
extends PanelContainer

signal character_attribute_selected(character_attribute: CharacterAttribute)
signal character_attribute_deselected(character_attribute: CharacterAttribute)

@export_group("Configuration")
@export var _button: DisplayButton
@export var _icon: TextureRect
@export var _descriptor: Label
@export var _details: RichTextLabel
@export var _color: ColorRect
@export var _score: RichTextLabel

var attribute: CharacterAttribute :
	set(new_attribute):
		assert(new_attribute)
		assert(new_attribute != attribute)
		attribute = new_attribute
		_icon.texture = attribute.icon
		_descriptor.text = attribute.descriptor
		_details.text = attribute.details
		_color.color = attribute.color
		tooltip_text = attribute.details

var score: BaseAttributeScore :
	set(new_score):
		score = new_score
		update()

var modifiers: Array[AttributeScore.Modifier] = [] :
	set(new_modifiers):
		modifiers = new_modifiers
		update()

func setup(radio_button_group: ButtonGroup) -> void:
	_button.button_group = radio_button_group

func update() -> void:
	var attribute_score: AttributeScore = _get_attribute_score()
	_score.text = "%s = %d" % [attribute_score.get_details(), attribute_score.get_score()]

func enable() -> void:
	_button.disable()

func disable() -> void:
	_button.disable()

func _get_attribute_score() -> AttributeScore:
	return AttributeScore.create_with_modifiers(attribute, score, modifiers)

func _on_button_toggled(toggled_on: bool) -> void:
	if toggled_on: character_attribute_selected.emit(attribute)
	else: character_attribute_deselected.emit(attribute)
