@tool
class_name AdventureUidInspector
extends EditorInspectorPlugin

## Shows the back-pointers that are stored as file UIDs ([member AdventureEncounter.places], stage conditions' subjects, …) as resource pickers
## with the resources' titles instead of uid:// strings: drop a file in, pick it, clear it; lists get a row per entry. The value stays a UID.

## "Class.property" -> [the types it takes, what empty means (none: nothing)]; looked up along the script's bases
const FIELDS: Dictionary[String, Array] = {
	"AdventureEncounter.places": ["AdventureLocation", ""],
	"AdventureEvent.only_at": ["AdventureLocation,AdventureArea", ""],
	"AdventureLocation.order": ["AdventureEncounter,AdventureLocation", ""],
	"AdventureStageCondition.subject": ["AdventureEncounter,AdventureLocation", "its own encounter, or the current location"],
	"AdventureStageConsequence.subject": ["AdventureEncounter,AdventureLocation", "its own encounter, or the current location"],
	"AdventureMoveConsequence.encounter": ["AdventureEncounter", "its own encounter"],
	"AdventureMoveConsequence.to": ["AdventureLocation", "here"],
	"AdventurePlaceCondition.encounter": ["AdventureEncounter", "its own encounter"],
	"AdventurePlaceCondition.at": ["AdventureLocation,AdventureArea", "here"],
	"AdventureFightDecision.encounter": ["AdventureEncounter", "its own encounter"],
	"AdventureTransition._leads_to": ["AdventurePage", "nowhere"],
}

func _can_handle(object: Object) -> bool: return object is Resource and object.get_script() != null

func _parse_property(object: Object, type: Variant.Type, name: String, _hint_type: PropertyHint, _hint_string: String, _usage_flags: int, _wide: bool) -> bool:
	var field: Array = get_field(object.get_script(), name)
	if field.is_empty(): return false
	var editor: EditorProperty = UidList.new(field[0]) if type == TYPE_ARRAY else UidProperty.new(field[0], field[1])
	add_property_editor(name, editor)
	return true

## The field of [param property] on [param script] or its bases ([constant FIELDS]); empty: not one of them
static func get_field(script: Script, property: String) -> Array:
	while script != null:
		var key: String = "%s.%s" % [script.get_global_name(), property]
		if FIELDS.has(key): return FIELDS[key]
		script = script.get_base_script()
	return [ ]

## The UID of a resource that is a file of its own; empty for one stored inside another file (nothing can point in there)
static func get_uid(resource: Resource) -> String:
	if resource == null: return ""
	if resource.resource_path.is_empty() or resource.resource_path.contains("::"):
		push_warning("%s is stored inside another file; only files of their own can be pointed at" % resource)
		return ""
	return AdventureLayout.get_key(resource)

## A title worth showing next to the picker: a page's or an area's name
static func describe(resource: Resource) -> String:
	if resource is AdventurePage: return AdventureGraph.get_title(resource as AdventurePage)
	if resource is AdventureArea: return (resource as AdventureArea).name
	return ""

static func make_picker(base_type: String, resource: Resource) -> EditorResourcePicker:
	var picker: EditorResourcePicker = EditorResourcePicker.new()
	picker.base_type = base_type
	picker.edited_resource = resource
	picker.editable = true
	picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return picker

## One UID; [param empty] says what an empty one means
class UidProperty:
	extends EditorProperty

	var _base_type: String
	var _empty: String
	var _picker: EditorResourcePicker
	var _label: Label

	func _init(base_type: String, empty: String) -> void:
		_base_type = base_type
		_empty = empty
		var column: VBoxContainer = VBoxContainer.new()
		_picker = AdventureUidInspector.make_picker(base_type, null)
		_picker.resource_changed.connect(_on_picked)
		column.add_child(_picker)
		_label = Label.new()
		_label.modulate = Color(1, 1, 1, 0.7)
		_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		column.add_child(_label)
		add_child(column)
		add_focusable(_picker)

	func _update_property() -> void:
		var path: String = get_edited_object().get(get_edited_property()) as String
		var resource: Resource = Files.load_existing(path)
		_picker.edited_resource = resource
		var title: String = AdventureUidInspector.describe(resource)
		if resource == null and not path.is_empty(): _label.text = "Missing: %s" % path
		elif resource == null: _label.text = "Empty: %s" % _empty if not _empty.is_empty() else ""
		else: _label.text = title
		_label.visible = not _label.text.is_empty()

	func _on_picked(resource: Resource) -> void:
		var uid: String = AdventureUidInspector.get_uid(resource)
		if resource != null and uid.is_empty():
			_update_property()
			return
		emit_changed(get_edited_property(), uid)

## A list of UIDs: a row per entry (✕ takes it out), an empty picker below adds one
class UidList:
	extends EditorProperty

	var _base_type: String
	var _rows: VBoxContainer

	func _init(base_type: String) -> void:
		_base_type = base_type
		_rows = VBoxContainer.new()
		add_child(_rows)
		set_bottom_editor(_rows)

	func _update_property() -> void:
		for row: Node in _rows.get_children(): row.queue_free()
		var paths: Array[String] = _get_paths()
		for index: int in paths.size():
			var row: HBoxContainer = HBoxContainer.new()
			var resource: Resource = Files.load_existing(paths[index])
			var picker: EditorResourcePicker = AdventureUidInspector.make_picker(_base_type, resource)
			picker.resource_changed.connect(_on_replaced.bind(index))
			row.add_child(picker)
			var label: Label = Label.new()
			label.text = AdventureUidInspector.describe(resource) if resource != null else "Missing: %s" % paths[index]
			label.modulate = Color(1, 1, 1, 0.7)
			row.add_child(label)
			var remove: Button = Button.new()
			remove.icon = AdventureActionMenu.get_editor_icon("Remove")
			remove.tooltip_text = "Take it out"
			remove.flat = true
			remove.pressed.connect(_on_removed.bind(index))
			row.add_child(remove)
			_rows.add_child(row)
		var adding: EditorResourcePicker = AdventureUidInspector.make_picker(_base_type, null)
		adding.tooltip_text = "Drop or pick one to add it"
		adding.resource_changed.connect(_on_added)
		_rows.add_child(adding)

	func _get_paths() -> Array[String]:
		var paths: Array[String] = [ ]
		var stored: Array = get_edited_object().get(get_edited_property())
		paths.assign(stored)
		return paths

	func _on_added(resource: Resource) -> void:
		var uid: String = AdventureUidInspector.get_uid(resource)
		var paths: Array[String] = _get_paths()
		if uid.is_empty() or paths.has(uid):
			_update_property()
			return
		paths.append(uid)
		emit_changed(get_edited_property(), paths)

	func _on_replaced(resource: Resource, index: int) -> void:
		var uid: String = AdventureUidInspector.get_uid(resource)
		var paths: Array[String] = _get_paths()
		if resource == null: paths.remove_at(index)
		elif uid.is_empty() or paths.has(uid):
			_update_property()
			return
		else: paths[index] = uid
		emit_changed(get_edited_property(), paths)

	func _on_removed(index: int) -> void:
		var paths: Array[String] = _get_paths()
		paths.remove_at(index)
		emit_changed(get_edited_property(), paths)
