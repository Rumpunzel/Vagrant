@tool
class_name OriginsPicker
extends VBoxContainer

signal origins_picked(kin: Origin, ilk: Origin)

@export var _kin_list: ItemList
@export var _ilk_list: ItemList
@export var _kin_ability: RichTextLabel
@export var _ilk_ability: RichTextLabel
@export var _continue: Button

var _selected_kin: Origin = null
var _selected_ilk: Origin = null
var _available_doubles: int

func _ready() -> void:
	if not Engine.is_editor_hint(): return
	setup(0)

func setup(rare_options: int) -> void:
	_kin_list.clear()
	_ilk_list.clear()
	# TODO: animate this
	visible = true
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	_available_doubles = rare_options
	for origin: Origin in Rules.ORIGINS:
		var kin_index: int = _kin_list.add_item(origin.name, origin.icon)
		var ilk_index: int = _ilk_list.add_item(origin.name, origin.icon)
		_kin_list.set_item_metadata(kin_index, origin)
		_ilk_list.set_item_metadata(ilk_index, origin)
		_kin_list.set_item_tooltip(kin_index, origin.details)
		_ilk_list.set_item_tooltip(ilk_index, origin.details)
		if not origin.type == Origin.Type.RARE: continue
		_kin_list.set_item_icon_modulate(kin_index, Color.GOLD)
		_ilk_list.set_item_icon_modulate(ilk_index, Color.GOLD)
		if _available_doubles > 0: continue
		_kin_list.set_item_disabled(kin_index, true)
		_ilk_list.set_item_disabled(ilk_index, true)

func collapse() -> void:
	_continue.disabled = true
	# TODO: animate this
	_continue.visible = false
	size_flags_vertical = Control.SIZE_FILL

func _is_ready() -> bool:
	if not _selected_kin or not _selected_ilk: return false
	var selected_rares: int = 0
	if _selected_kin.type == Origin.Type.RARE: selected_rares += 1
	if _selected_ilk.type == Origin.Type.RARE: selected_rares += 1
	return selected_rares == 2 or selected_rares == _available_doubles

func _after_on_select(selected: Origin, other_list: ItemList) -> void:
	assert(selected)
	for index: int in other_list.item_count:
		var origin: Origin = other_list.get_item_metadata(index)
		other_list.set_item_disabled(index, origin == selected)
	if not _is_ready(): return
	_continue.disabled = false
	_continue.grab_focus()

func _update_rare_origins(list: ItemList, rares_selected_in_other_lists: int) -> void:
	var available: bool = _available_doubles - rares_selected_in_other_lists > 0
	for index: int in list.item_count:
		var origin: Origin = list.get_item_metadata(index)
		if origin.type == Origin.Type.RARE: list.set_item_disabled(index, not available)

func _on_kin_list_item_selected(index: int) -> void:
	_selected_kin = _kin_list.get_item_metadata(index)
	_kin_ability.text = _selected_kin.ability
	_after_on_select(_selected_kin, _ilk_list)
	_update_rare_origins(_ilk_list, 1 if _selected_kin.type == Origin.Type.RARE else 0)

func _on_ilk_list_item_selected(index: int) -> void:
	_selected_ilk = _ilk_list.get_item_metadata(index)
	_ilk_ability.text = _selected_ilk.ability
	_after_on_select(_selected_ilk, _kin_list)
	_update_rare_origins(_kin_list, 1 if _selected_ilk.type == Origin.Type.RARE else 0)

func _on_continue_pressed() -> void:
	origins_picked.emit(_selected_kin, _selected_ilk)
