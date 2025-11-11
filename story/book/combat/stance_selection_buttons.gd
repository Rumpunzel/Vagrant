@tool
class_name StanceSelectionButtons
extends PanelContainer

enum Direction {
	Horizontal,
	Vertical,
}

@export_range(0.0, 256.0, 1.0, "exp", "suffix:px") var _button_size: float = 64.0
@export var _direction: Direction = Direction.Horizontal :
	set(new_direction):
		_direction = new_direction
		if _buttons:
			_stance_selection_buttons_parent.remove_child(_buttons)
			_buttons.queue_free()
		match _direction:
			Direction.Horizontal: _buttons = HBoxContainer.new()
			Direction.Vertical: _buttons = VBoxContainer.new()
			_: assert(false, "Does not exist")
		_buttons.add_theme_constant_override("separation", 16)
		_stance_selection_buttons_parent.add_child(_buttons)

@export_group("Configuration")
@export var _stance_selection_buttons_parent: Container
@export var _stance_selection_button: PackedScene

var _character_resolver: Callable
var _save_request: SaveRequest :
	set(new_save_request):
		assert(new_save_request)
		_save_request = new_save_request
		for button: StanceSelection in _get_buttons():
			button.character = _character_resolver.call(_save_request.character_profile)
		var relevant_stance_selection: StanceSelection = _button[_save_request.attribute]
		relevant_stance_selection.select()

var _buttons: BoxContainer
var _button: Dictionary[CharacterAttribute, StanceSelection] = {}

func _ready() -> void:
	setup_character_attributes(Rules.ATTRIBUTES)

func setup_character_attributes(character_attributes: Array[CharacterAttribute]) -> void:
	_clear()
	var radio_button_group: ButtonGroup = ButtonGroup.new()
	for character_attribute: CharacterAttribute in character_attributes:
		add_button(character_attribute, radio_button_group, _button_size)

func request_save(save_request: SaveRequest, character_resolver: Callable) -> void:
	assert(save_request)
	assert(character_resolver)
	_character_resolver = character_resolver
	_save_request = save_request

func enable_buttons() -> void:
	for button: StanceSelection in _get_buttons(): button.enable()

func disable_buttons() -> void:
	for button: StanceSelection in _get_buttons(): button.disable()

func add_button(character_attribute: CharacterAttribute, radio_button_group: ButtonGroup, button_size: float) -> void:
	assert(character_attribute)
	assert(radio_button_group)
	var button: StanceSelection = _stance_selection_button.instantiate()
	button.attribute = character_attribute
	button.setup(radio_button_group)
	button.custom_minimum_size = Vector2(button_size, button_size)
	match _direction:
		Direction.Horizontal: button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		Direction.Vertical: button.size_flags_vertical = Control.SIZE_EXPAND_FILL
		_: assert(false, "Does not exist")
	_button[character_attribute] = button
	button.character_attribute_selected.connect(_on_character_attribute_selected)
	_buttons.add_child(button)

func _clear() -> void:
	if not _buttons:
		_direction = _direction
		return
	for child: Node in _buttons.get_children():
		_buttons.remove_child(child)
		child.queue_free()

func _get_buttons() -> Array[StanceSelection]:
	var buttons: Array[StanceSelection] = []
	buttons.assign(_buttons.get_children())
	return buttons

func _on_character_attribute_selected(character_attribute: CharacterAttribute) -> void:
	assert(character_attribute)
	_save_request.attribute = character_attribute
	_save_request.update_auto_selected_breath_dice(_character_resolver)
