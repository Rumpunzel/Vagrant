@tool
class_name StanceSelection
extends PanelContainer

signal character_attribute_selected(character_attribute: CharacterAttribute)
signal character_attribute_deselected(character_attribute: CharacterAttribute)

@export var attribute: CharacterAttribute :
	set(new_attribute):
		assert(new_attribute)
		assert(new_attribute != attribute)
		attribute = new_attribute
		_button.set_button_highlight_colors(attribute.color)
		_score.modulate = attribute.color.darkened(0.5)
		_icon.texture = attribute.icon
		tooltip_text = attribute.details

@export_group("Configuration")
@export var _button: DisplayButton
@export var _score: Label
@export var _icon: TextureRect
@export var _details: RichTextLabel

func setup(radio_button_group: ButtonGroup) -> void:
	_button.button_group = radio_button_group

func request_fight(fight_request: FightRequest) -> void:
	_score.text = "%d" % fight_request.character.get_attribute_score(attribute).get_score()
	_details.text = fight_request.get_stance_description(attribute)

func select() -> void:
	_button.button_pressed = true
	if not get_viewport().gui_get_focus_owner(): _button.grab_focus()

func enable() -> void:
	_button.disable()

func disable() -> void:
	_button.disable()

func _on_button_toggled(toggled_on: bool) -> void:
	if toggled_on: character_attribute_selected.emit(attribute)
	else: character_attribute_deselected.emit(attribute)
