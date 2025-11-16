@tool
class_name StanceSelection
extends CarouselSelection

signal attribute_selected(attribute: CharacterAttribute)

@export var attribute: CharacterAttribute : set = set_attribute

func _ready() -> void:
	items.assign(Rules.ATTRIBUTES.map(func(character_attribute: CharacterAttribute) -> String: return character_attribute.descriptor))

func get_panel() -> StancePanel:
	assert(_panel is StancePanel)
	return _panel

func setup_for_fight(fight_request: FightRequest) -> void:
	attribute = fight_request.attribute
	get_panel().setup_for_fight(fight_request)

func set_attribute(new_attribute: CharacterAttribute) -> void:
	assert(new_attribute)
	if new_attribute == attribute: return
	attribute = new_attribute
	if not is_node_ready(): await  ready
	get_panel().setup(attribute.descriptor)
	## Previous
	var previous_attribute: CharacterAttribute = Rules.ATTRIBUTES[posmod(selected - 1, Rules.ATTRIBUTES.size())]
	_previous.set_icon_colors(previous_attribute.color)
	_previous.tooltip_trigger.tooltip_strings = previous_attribute.abilities
	## Next
	var next_attribute: CharacterAttribute = Rules.ATTRIBUTES[posmod(selected + 1, Rules.ATTRIBUTES.size())]
	_next.set_icon_colors(next_attribute.color)
	_next.tooltip_trigger.tooltip_strings = next_attribute.abilities
	## Signal
	attribute_selected.emit(attribute)

func _set_selected(new_index: int) -> void:
	super._set_selected(new_index)
	attribute = Rules.ATTRIBUTES[selected]
