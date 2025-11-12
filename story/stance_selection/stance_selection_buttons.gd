@tool
class_name StanceSelectionButtons
extends PanelContainer

signal character_attribute_selected(character_attribute: CharacterAttribute)

@export_group("Configuration")
@export var _stance_selection: StanceSelection
@export var _previous: StanceSelectionButton
@export var _next: StanceSelectionButton

var fight_request: FightRequest :
	set(new_fight_request):
		assert(new_fight_request)
		fight_request = new_fight_request
		_stance_selection.fight_request = fight_request
		_previous.attribute = _get_previous_attribue(fight_request.attribute)
		_next.attribute = _get_next_attribue(fight_request.attribute)
		fight_request.attribute_changed.connect(_on_attribute_changed)

func enable_buttons() -> void:
	_previous.enable()
	_next.enable()

func disable_buttons() -> void:
	_previous.disable()
	_next.disable()

func _get_previous_attribue(attribute: CharacterAttribute) -> CharacterAttribute:
	var attribute_count: int = Rules.ATTRIBUTES.size()
	var index: int = Rules.ATTRIBUTES.find(attribute)
	var previous_index: int = index - 1 + attribute_count
	return Rules.ATTRIBUTES[previous_index % attribute_count]

func _get_next_attribue(attribute: CharacterAttribute) -> CharacterAttribute:
	var attribute_count: int = Rules.ATTRIBUTES.size()
	var index: int = Rules.ATTRIBUTES.find(attribute)
	var next_index: int = index + 1
	return Rules.ATTRIBUTES[next_index % attribute_count]

func _on_attribute_changed(attribute: CharacterAttribute) -> void:
	_stance_selection.attribute = attribute
	_previous.attribute = _get_previous_attribue(attribute)
	_next.attribute = _get_next_attribue(attribute)
	character_attribute_selected.emit(attribute)

func _on_previous_pressed() -> void:
	assert(fight_request)
	fight_request.attribute = _previous.attribute

func _on_next_pressed() -> void:
	assert(fight_request)
	fight_request.attribute = _next.attribute
