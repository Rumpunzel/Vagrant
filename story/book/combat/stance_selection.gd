@tool
class_name StanceSelection
extends PanelContainer

signal character_attribute_selected(character_attribute: CharacterAttribute)
signal character_attribute_deselected(character_attribute: CharacterAttribute)

@export_group("Configuration")
@export var _button: DisplayButton
@export var _score: Label
@export var _icon: TextureRect
@export var _details: RichTextLabel

var attribute: CharacterAttribute :
	set(new_attribute):
		assert(new_attribute)
		assert(new_attribute != attribute)
		attribute = new_attribute
		_button.set_button_highlight_colors(attribute.color)
		if character: _score.text = "%d" % character.get_attribute_score(attribute).get_score()
		_score.modulate = attribute.color.darkened(0.5)
		_icon.texture = attribute.icon
		_details.text = attribute.details
		tooltip_text = attribute.details

var character: Character :
	set(new_character):
		assert(new_character)
		assert(new_character != character)
		character = new_character
		_score.text = "%d" % character.get_attribute_score(attribute).get_score()

func setup(radio_button_group: ButtonGroup) -> void:
	_button.button_group = radio_button_group

func select() -> void:
	_button.button_pressed = true

func enable() -> void:
	_button.disable()

func disable() -> void:
	_button.disable()

func _on_button_toggled(toggled_on: bool) -> void:
	if toggled_on: character_attribute_selected.emit(attribute)
	else: character_attribute_deselected.emit(attribute)
