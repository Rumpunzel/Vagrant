@tool
class_name DieCarouselSelection
extends CarouselSelection

signal die_type_selected(die_type: DieType)

@export var die_types: Array[DieType] :
	set(new_die_types):
		die_types = new_die_types
		items.assign(die_types.map(func(die_type: DieType) -> String: return die_type.to_string()))
		selected = 0

func _ready() -> void:
	if not Engine.is_editor_hint(): return
	die_types = [Rules.d4, Rules.d6, Rules.d8, Rules.d10, Rules.d12]

func get_panel() -> DieCarouselPanel:
	assert(_panel is DieCarouselPanel)
	return _panel

func get_item_count() -> int:
	return die_types.size()

func _set_selected(new_index: int) -> void:
	super._set_selected(new_index)
	if selected < 0:
		die_type_selected.emit(null)
		return
	if not is_node_ready(): await ready
	var selected_die_type: DieType = die_types[selected]
	get_panel().die_type = selected_die_type
	die_type_selected.emit(selected_die_type)
