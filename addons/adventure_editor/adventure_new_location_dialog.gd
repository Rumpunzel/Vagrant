@tool
class_name AdventureNewLocationDialog
extends ConfirmationDialog

## Asks for a new location's title and area (an existing one, or a new one by name)

## [param area]: none means a new area called [param new_area_name]
signal location_confirmed(title: String, area: AdventureArea, new_area_name: String, at: Vector2)

const NEW_AREA: String = "New area…"

var _title: LineEdit
var _areas: OptionButton
var _new_area_name: LineEdit
var _at: Vector2

func _init() -> void:
	title = "New location"
	var fields: VBoxContainer = VBoxContainer.new()
	_title = LineEdit.new()
	_title.placeholder_text = "Title"
	_areas = OptionButton.new()
	_areas.item_selected.connect(func(_index: int) -> void: _new_area_name.visible = _areas.get_selected_metadata() == null)
	_new_area_name = LineEdit.new()
	_new_area_name.placeholder_text = "Area name"
	for control: Control in [_title, _areas, _new_area_name]: fields.add_child(control)
	add_child(fields)
	register_text_enter(_title)
	confirmed.connect(_on_confirmed)

func open(areas: Array[AdventureArea], at: Vector2) -> void:
	_at = at
	_title.clear()
	_new_area_name.clear()
	_areas.clear()
	for area: AdventureArea in areas:
		_areas.add_item(area.name)
		_areas.set_item_metadata(_areas.item_count - 1, area)
	_areas.add_item(NEW_AREA)
	_areas.set_item_metadata(_areas.item_count - 1, null)
	_areas.select(0)
	_new_area_name.visible = areas.is_empty()
	popup_centered(Vector2i(320, 0))
	_title.grab_focus()

func _on_confirmed() -> void:
	var area: AdventureArea = _areas.get_selected_metadata() as AdventureArea
	if _title.text.strip_edges().is_empty() or area == null and _new_area_name.text.strip_edges().is_empty(): return
	location_confirmed.emit(_title.text.strip_edges(), area, _new_area_name.text.strip_edges(), _at)
