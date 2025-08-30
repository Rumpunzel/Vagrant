@tool
class_name OriginsPicker
extends VBoxContainer

signal origins_picked(origins: Array[Origin])
signal origins_unpicked

@export_dir var _origins_directory: String
@export var _search_recursively: bool = false

@export_group("Configuration")
@export var _origins_list: ItemList
@export var _ability_labels: Array[AbilityLabel]

var _selected_origins: Array[Origin] = [null, null]
var _origin_indexes: Dictionary[Origin, int] = {}
var _available_doubles: int

@onready var _available_origins: Array[Origin]

func _ready() -> void:
	assert(_ability_labels.size() == _selected_origins.size())
	var origin_files: Array[String] = Rules.list_all_files(_origins_directory, _search_recursively, func(file_name: String) -> bool: return file_name.get_extension() == "tres")
	_available_origins.assign(origin_files.map(func(origin_file: String) -> Origin: return load(origin_file)))
	_update_ability_labels()
	if Engine.is_editor_hint(): setup(0)

func setup(rare_options: int) -> void:
	_origins_list.clear()
	_available_doubles = rare_options
	for origin: Origin in _available_origins:
		var origin_index: int = _origins_list.add_item(origin.name, origin.icon)
		_origin_indexes[origin] = origin_index
		_origins_list.set_item_metadata(origin_index, origin)
		_origins_list.set_item_tooltip(origin_index, origin.details)
		if origin.type == Origin.Type.RARE: _origins_list.set_item_icon_modulate(origin_index, Color.GOLD)
	# Pick random origins
	while _selected_origins.has(null):
		var origin_index: int = randi_range(0, _origins_list.item_count - 1)
		var random_origin: Origin = _origins_list.get_item_metadata(origin_index)
		if _selected_origins.has(random_origin) or not _is_available(random_origin.type): continue
		_origins_list.select(origin_index, false)
		_on_origins_multi_selected(origin_index, true)

func appear() -> void:
	# TODO: animate this
	visible = true

func _unpick_origin(origin: Origin) -> void:
	var origin_index: int = _selected_origins.find(origin)
	assert(origin_index >= 0)
	_selected_origins.pop_at(origin_index)
	_selected_origins.push_back(null)
	origins_unpicked.emit()

func _override_oldest_origin(origin: Origin) -> void:
	var oldest_origin: Origin = null
	for origin_index: int in _selected_origins.size():
		var selected_origin: Origin = _selected_origins[origin_index]
		if selected_origin and selected_origin.type == origin.type:
			oldest_origin = selected_origin
			break
	if not oldest_origin: oldest_origin = _selected_origins.front()
	var oldest_index: int = _selected_origins.find(oldest_origin)
	_selected_origins.pop_at(oldest_index)
	_origins_list.deselect(_origin_indexes[oldest_origin])
	_selected_origins.push_back(origin)
	_selected_origins.sort_custom(func(first: Origin, second: Origin) -> bool: return first != null and second == null)
	if _is_ready(): origins_picked.emit(_selected_origins)

func _is_ready() -> bool:
	for type: Origin.Type in Origin.Type.values():
		if _get_remaining(type) > 0: return false
	return true

func _update_origins() -> void:
	for origin_index: int in _origins_list.item_count:
		var selected_origin: Origin = _origins_list.get_item_metadata(origin_index)
		var available: bool = _selected_origins.has(selected_origin) or _is_available(selected_origin.type)
		_origins_list.set_item_disabled(origin_index, not available)

func _update_ability_labels() -> void:
	for origin_index: int in _selected_origins.size():
		var origin: Origin = _selected_origins[origin_index]
		_ability_labels[origin_index].origin = origin

func _is_available(type: Origin.Type) -> bool:
	match type:
		Origin.Type.NORMAL: if _selected_origins.size() - _available_doubles <= 0: return false
		Origin.Type.RARE: if _available_doubles <= 0: return false
		_: assert(false, "Origin.Type %s is not supported!" % type)
	return _get_remaining(type) >= 0

func _get_remaining(type: Origin.Type) -> int:
	var remaining: int
	match type:
		Origin.Type.NORMAL: remaining = _selected_origins.size() - _available_doubles
		Origin.Type.RARE: remaining = _available_doubles
		_: assert(false, "Origin.Type %s is not supported!" % type)
	for origin: Origin in _selected_origins:
		if origin and origin.type == type: remaining -= 1
	return remaining

func _on_origins_multi_selected(index: int, selected: bool) -> void:
	assert(_selected_origins.size() == 2)
	var origin: Origin = _origins_list.get_item_metadata(index)
	if not selected: _unpick_origin(origin)
	elif not _selected_origins.has(null) or _get_remaining(origin.type) == 0:
		_override_oldest_origin(origin)
	else:
		for slot_index: int in _selected_origins.size():
			if not _selected_origins[slot_index]:
				_selected_origins[slot_index] = origin
				break
		if _is_ready(): origins_picked.emit(_selected_origins)
	assert(_selected_origins.size() == 2)
	_update_origins()
	_update_ability_labels()
