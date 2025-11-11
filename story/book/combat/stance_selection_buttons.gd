@tool
class_name StanceSelectionButtons
extends PanelContainer

@export_group("Configuration")
@export var _buttons: FlexContainer
@export var _stance_selection_button: PackedScene

var _character_resolver: Callable
var _save_request: SaveRequest :
	set(new_save_request):
		assert(new_save_request)
		_save_request = new_save_request
		_buttons.for_each_element(func(button: StanceSelection) -> void: button.character = _character_resolver.call(_save_request.character_profile))
		var relevant_stance_selection: StanceSelection = _stance_selections[_save_request.attribute]
		relevant_stance_selection.select()

var _stance_selections: Dictionary[CharacterAttribute, StanceSelection] = {}

func _ready() -> void:
	setup_character_attributes(Rules.ATTRIBUTES)

func setup_character_attributes(character_attributes: Array[CharacterAttribute]) -> void:
	_stance_selections.clear()
	_buttons.clear()
	var radio_button_group: ButtonGroup = ButtonGroup.new()
	for character_attribute: CharacterAttribute in character_attributes:
		add_button(character_attribute, radio_button_group)

func request_save(save_request: SaveRequest, character_resolver: Callable) -> void:
	assert(save_request)
	assert(character_resolver)
	_character_resolver = character_resolver
	_save_request = save_request

func enable_buttons() -> void:
	_buttons.for_each_element(func(button: StanceSelection) -> void: button.enable())

func disable_buttons() -> void:
	_buttons.for_each_element(func(button: StanceSelection) -> void: button.disable())

func add_button(character_attribute: CharacterAttribute, radio_button_group: ButtonGroup) -> void:
	assert(character_attribute)
	assert(radio_button_group)
	var button: StanceSelection = _stance_selection_button.instantiate()
	button.attribute = character_attribute
	button.setup(radio_button_group)
	button.character_attribute_selected.connect(_on_character_attribute_selected)
	_stance_selections[character_attribute] = button
	_buttons.add(button)

func _on_character_attribute_selected(character_attribute: CharacterAttribute) -> void:
	assert(character_attribute)
	_save_request.attribute = character_attribute
	_save_request.update_auto_selected_breath_dice(_character_resolver)
