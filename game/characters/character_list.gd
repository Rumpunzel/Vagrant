@tool
@abstract
class_name CharacterList
extends PanelContainer

@export var characters: Characters : set = set_characters

@export_group("Layout")
@export var margin_left: int = 0 :
	set(new_margin_left):
		margin_left = new_margin_left
		_character_list.add_theme_constant_override("margin_left", new_margin_left)
@export var margin_top: int = 0 :
	set(new_margin_top):
		margin_top = new_margin_top
		_character_list.add_theme_constant_override("margin_top", margin_top)
@export var margin_right: int = 0 :
	set(new_margin_right):
		margin_right = new_margin_right
		_character_list.add_theme_constant_override("margin_right", margin_right)
@export var margin_bottom: int = 0 :
	set(new_margin_bottom):
		margin_bottom = new_margin_bottom
		_character_list.add_theme_constant_override("margin_bottom", margin_bottom)
@export var fill: bool = false :
	set(new_fill):
		fill = new_fill
		_character_list.fill = fill
@export var flex_alignment: BoxContainer.AlignmentMode = BoxContainer.AlignmentMode.ALIGNMENT_BEGIN :
	set(new_flex_alignment):
		flex_alignment = new_flex_alignment
		_character_list.alignment = flex_alignment
@export var direction: FlexContainer.Direction :
	get: return _character_list.direction
	set(new_direction): _character_list.direction = new_direction

var _character_list: FlexContainer

func _init() -> void:
	_setup_flex_container()

func _update_character_list(updated_characters: Dictionary[CharacterProfile, Character]) -> void:
	_character_list.clear()
	for character: Character in updated_characters.values(): _character_list.add(_create_character_entry(character))

@abstract func _create_character_entry(character: Character) -> Control

func _setup_flex_container() -> void:
	assert(not _character_list)
	_character_list = FlexContainer.new()
	_character_list.name = "Characters"
	_character_list.fill = fill
	_character_list.alignment = flex_alignment
	_character_list.direction = direction
	_character_list.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_character_list.add_theme_constant_override("margin_left", margin_left)
	_character_list.add_theme_constant_override("margin_top", margin_top)
	_character_list.add_theme_constant_override("margin_right", margin_right)
	_character_list.add_theme_constant_override("margin_bottom", margin_bottom)
	add_child(_character_list, true, Node.INTERNAL_MODE_BACK)

func set_characters(new_characters: Characters) -> void:
	assert(not characters)
	assert(new_characters)
	characters = new_characters
	_update_character_list(characters.characters)
	characters.characters_updated.connect(_update_character_list)
