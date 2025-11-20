@tool
class_name DieCarouselSelection
extends CarouselSelection

signal die_type_selected(die_type: DieType)

@export var die_types: Array[DieType] :
	set(new_die_types):
		die_types = new_die_types
		if include_null_die: die_types.append(null)
		items.assign(die_types.map(func(die_type: DieType) -> String: return die_type.to_string() if die_type else ("NONE" if null_text.is_empty() else null_text)))
		selected = 0
@export var include_null_die: bool
@export_placeholder("NONE") var null_text: String

func _ready() -> void:
	if not Engine.is_editor_hint(): return
	die_types = [Rules.d4, Rules.d6, Rules.d8, Rules.d10, Rules.d12]

func get_panel() -> DieCarouselPanel:
	assert(_panel is DieCarouselPanel)
	return _panel

func get_item_count() -> int:
	return die_types.size()

func get_selected_die_type() -> DieType:
	return die_types[selected]

func set_selected_die_type(die_type: DieType) -> void:
	selected = die_types.find(die_type)

func _set_selected(new_index: int) -> void:
	super._set_selected(new_index)
	if Engine.is_editor_hint(): return
	if selected < 0:
		die_type_selected.emit(null)
		return
	if not is_node_ready(): await ready
	var selected_die_type: DieType = die_types[selected]
	get_panel().die_type = selected_die_type
	die_type_selected.emit(selected_die_type)
