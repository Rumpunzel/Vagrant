@tool
class_name StanceSelection
extends CarouselSelection

signal attribute_selected(attribute: CharacterAttribute)

func _ready() -> void:
	items.assign(Rules.ATTRIBUTES.map(func(character_attribute: CharacterAttribute) -> String: return character_attribute.descriptor))

func setup_for_fight(fight_request: FightRequest) -> void:
	get_panel().setup_for_fight(fight_request)
	set_selected_attribute(fight_request.attribute)

func set_selected_attribute(attribute: CharacterAttribute) -> void:
	assert(attribute)
	var attribute_index: int = Rules.ATTRIBUTES.find(attribute)
	if attribute_index == selected: return
	selected = attribute_index

func get_panel() -> StancePanel:
	assert(_panel is StancePanel)
	return _panel

func get_previous() -> CarouselButton:
	assert(_previous is CarouselButton)
	return _previous

func get_next() -> CarouselButton:
	assert(_next is CarouselButton)
	return _next

func _set_selected_attribute(attribute: CharacterAttribute) -> void:
	assert(attribute)
	if not is_node_ready(): await  ready
	get_panel().attribute = attribute
	## Previous
	var previous_attribute: CharacterAttribute = Rules.ATTRIBUTES[posmod(selected - 1, Rules.ATTRIBUTES.size())]
	_previous.set_icon_colors(previous_attribute.color)
	get_previous().tooltip_trigger.tooltip_strings = previous_attribute.abilities
	## Next
	var next_attribute: CharacterAttribute = Rules.ATTRIBUTES[posmod(selected + 1, Rules.ATTRIBUTES.size())]
	_next.set_icon_colors(next_attribute.color)
	get_next().tooltip_trigger.tooltip_strings = next_attribute.abilities
	## Signal
	attribute_selected.emit(attribute)

func _setup_carousel() -> void:
	super._setup_carousel()
	_previous.icon = preload("uid://buvbksy3o46rm")
	_next.icon = preload("uid://ctxdc156sk6t4")

func _set_selected(new_index: int) -> void:
	super._set_selected(new_index)
	if selected < 0:
		attribute_selected.emit(null)
		return
	_set_selected_attribute(Rules.ATTRIBUTES[selected])
