@tool
class_name AdventureEditor
extends VBoxContainer

## Main screen of the adventure editor plugin: one adventure as a map ([AdventureMapView]) and its events ([AdventureEventView]).
## The graphs edit structure (links, new locations, areas, events, pages and decisions) with undo; changes stay unsaved until [method save]. Content is edited in the Inspector.
## Selecting opens the resource there; moving nodes saves the [AdventureLayout] at once.

const INDENT: String = "    "

@export_group("Configuration")
@export var _picker: EditorResourcePicker
@export var _tabs: TabContainer
@export var _map: AdventureMapView
@export var _events_tab: Control
@export var _event_list: ItemList
@export var _host_picker: OptionButton
@export var _event_view: AdventureEventView

var adventure: Adventure : set = set_adventure

var _graph: AdventureGraph
var _layout: AdventureLayout
var _undo_redo: EditorUndoRedoManager
## Resources changed by edits and not saved yet
var _unsaved: Array[Resource] = [ ]
var _new_location_dialog: AdventureNewLocationDialog
var _name_dialog: AdventureNameDialog

## Called by the plugin, not in [method Node._ready], so opening this scene in the editor doesn't run it
func setup(undo_redo: EditorUndoRedoManager) -> void:
	_undo_redo = undo_redo
	_map.setup()
	_event_view.setup()
	_picker.resource_changed.connect(func(resource: Resource) -> void: set_adventure(resource as Adventure))
	_map.event_opened.connect(open_event)
	_event_view.event_opened.connect(open_event)
	_event_view.exit_opened.connect(_open_location)
	_map.layout_changed.connect(_save_layout)
	_event_view.layout_changed.connect(_save_layout)
	_event_list.item_selected.connect(func(index: int) -> void: _show_event(_event_list.get_item_metadata(index) as AdventurePage, null))
	_host_picker.item_selected.connect(func(index: int) -> void: _event_view.show_event(_event_view.get_event(), _host_picker.get_item_metadata(index) as AdventurePage))
	EditorInterface.get_inspector().property_edited.connect(_on_property_edited)
	_map.link_requested.connect(_link)
	_map.unlink_requested.connect(_unlink)
	_map.areas_requested.connect(_move_into_areas)
	_new_location_dialog = AdventureNewLocationDialog.new()
	_new_location_dialog.location_confirmed.connect(_create_location)
	add_child(_new_location_dialog)
	_map.location_requested.connect(_ask_for_location)
	_name_dialog = AdventureNameDialog.new()
	add_child(_name_dialog)
	_map.event_requested.connect(func(location: AdventurePage, scenario: bool) -> void:
		_name_dialog.ask("New scenario" if scenario else "New event", "Title", _create_event.bind(location, scenario))
	)
	_event_view.reference_requested.connect(_set_reference)
	_event_view.decisions_requested.connect(_set_decisions)
	_event_view.references_cleared.connect(_clear_references)
	_event_view.property_requested.connect(_set_property)
	_event_view.option_requested.connect(func(scenario: AdventureEventScenario) -> void: _name_dialog.ask("New option", "Title", _create_event.bind(scenario, false)))

func set_adventure(value: Adventure) -> void:
	adventure = value
	_picker.edited_resource = value
	_layout = AdventureLayout.load_for(value) if value != null else null
	_map.layout = _layout
	_event_view.layout = _layout
	_event_view.show_event(null)
	rebuild()
	_map.scroll_to_nodes()

func rebuild() -> void:
	var placed: Array[AdventurePage] = [ ]
	if _layout != null: placed = _layout.get_placed_pages()
	_graph = AdventureGraph.new(adventure, placed)
	_map.show_graph(_graph)
	_event_list.clear()
	var listed: Array[AdventurePage] = [ ]
	for event: AdventurePage in _graph.get_top_events(): _list_event(event, 0, listed)
	var current: AdventurePage = _event_view.get_event()
	if listed.has(current): _show_event(current, _event_view.get_host())
	else: _show_event(null, null)

## Shows [param event] in the events tab, at [param host] if given
func open_event(event: AdventurePage, host: AdventurePage) -> void:
	_tabs.current_tab = _tabs.get_tab_idx_from_control(_events_tab)
	_show_event(event, host)
	_event_view.scroll_to_nodes()

## Scenarios list their options below them, events the sub-events of their pages
func _list_event(event: AdventurePage, depth: int, listed: Array[AdventurePage]) -> void:
	if listed.has(event): return
	listed.append(event)
	var kind: String = " (scenario)" if event is AdventureEventScenario else ""
	var index: int = _event_list.add_item(INDENT.repeat(depth) + AdventureGraph.get_title(event) + kind)
	_event_list.set_item_metadata(index, event)
	_event_list.set_item_tooltip(index, event.resource_path)
	var nested: Array[AdventurePage] = event.events.duplicate()
	if not event is AdventureEventScenario:
		for page: AdventurePage in AdventureEventGraph.new(event).pages.slice(1): nested.append_array(page.events)
	for sub_event: AdventurePage in nested: _list_event(sub_event, depth + 1, listed)

func _show_event(event: AdventurePage, host: AdventurePage) -> void:
	_event_view.show_event(event, host)
	_event_list.deselect_all()
	for index: int in _event_list.item_count:
		if _event_list.get_item_metadata(index) == event: _event_list.select(index)
	_host_picker.clear()
	_host_picker.add_item("At any host")
	_host_picker.set_item_metadata(0, null)
	if event == null: return
	for location: AdventurePage in _graph.get_location_hosts(event):
		_host_picker.add_item("At %s" % AdventureGraph.get_title(location))
		_host_picker.set_item_metadata(_host_picker.item_count - 1, location)
		if location == host: _host_picker.select(_host_picker.item_count - 1)

func _open_location(location: AdventurePage) -> void:
	_tabs.current_tab = _tabs.get_tab_idx_from_control(_map)
	_map.focus_page(location)

func has_unsaved_changes() -> bool: return not _unsaved.is_empty()

func save() -> void:
	for resource: Resource in _unsaved: ResourceSaver.save(resource)
	_unsaved.clear()

func _shortcut_input(input: InputEvent) -> void:
	if not is_visible_in_tree() or not has_unsaved_changes(): return
	var key: InputEventKey = input as InputEventKey
	if key != null and key.pressed and key.keycode == KEY_S and key.is_command_or_control_pressed() and not key.shift_pressed:
		save()
		get_viewport().set_input_as_handled()

func _link(from: AdventurePage, to: AdventurePage) -> void:
	if from == null or to == null or from == to: return
	var decisions: Array[AdventureDecision] = from.decisions.duplicate()
	decisions.append(AdventureMapEditing.make_link(to))
	_undo_redo.create_action("Link %s to %s" % [AdventureGraph.get_title(from), AdventureGraph.get_title(to)], UndoRedo.MERGE_DISABLE, from)
	_change(from, &"decisions", decisions)
	_undo_redo.commit_action()

func _unlink(from: AdventurePage, to: AdventurePage) -> void:
	if from == null or to == null: return
	var decisions: Array[AdventureDecision] = AdventureMapEditing.without_links(from, to)
	if decisions.size() == from.decisions.size():
		push_warning("%s leads to %s only through a fight or save; change it in the events tab or the Inspector" % [AdventureGraph.get_title(from), AdventureGraph.get_title(to)])
		return
	_undo_redo.create_action("Unlink %s from %s" % [AdventureGraph.get_title(from), AdventureGraph.get_title(to)], UndoRedo.MERGE_DISABLE, from)
	_change(from, &"decisions", decisions)
	_undo_redo.commit_action()

func _move_into_areas(areas: Dictionary[AdventurePage, AdventureArea]) -> void:
	_undo_redo.create_action("Change area", UndoRedo.MERGE_DISABLE, areas.keys()[0])
	for page: AdventurePage in areas: _change(page, &"area", areas[page])
	_undo_redo.commit_action()

## [param reference]: none unlinks
func _set_reference(decision: AdventureDecision, property: StringName, reference: AdventurePageReference, file: Resource) -> void:
	_undo_redo.create_action("Unlink" if reference == null else "Link", UndoRedo.MERGE_DISABLE, file)
	_change(decision, property, reference, file)
	_undo_redo.commit_action()

## Adding, moving and removing a page's decisions
func _set_decisions(page: AdventurePage, decisions: Array[AdventureDecision], file: Resource, action: String) -> void:
	_undo_redo.create_action(action, UndoRedo.MERGE_DISABLE, file)
	_change(page, &"decisions", decisions, file)
	_undo_redo.commit_action()

func _set_property(resource: Resource, property: StringName, value: Variant, file: Resource, action: String) -> void:
	_undo_redo.create_action(action, UndoRedo.MERGE_DISABLE, file)
	_change(resource, property, value, file)
	_undo_redo.commit_action()

## Each [decision, property] to none, in one action (deleting a page)
func _clear_references(references: Array[Array], file: Resource, action: String) -> void:
	_undo_redo.create_action(action, UndoRedo.MERGE_DISABLE, file)
	for reference: Array in references: _change(reference[0], reference[1], null, file)
	_undo_redo.commit_action()

## Adds setting [param property] to the open action, both ways marking [param file] (none: [param resource] itself) unsaved and rebuilding
func _change(resource: Resource, property: StringName, value: Variant, file: Resource = null) -> void:
	_undo_redo.add_do_property(resource, property, value)
	_undo_redo.add_undo_property(resource, property, resource.get(property))
	_undo_redo.add_do_method(self, &"_changed", file if file != null else resource)
	_undo_redo.add_undo_method(self, &"_changed", file if file != null else resource)

func _changed(resource: Resource) -> void:
	if not _unsaved.has(resource): _unsaved.append(resource)
	rebuild()

func _ask_for_location(at: Vector2) -> void:
	if adventure != null: _new_location_dialog.open(_graph.areas, at)

## Creates the location's file (and a new area's) right away; Ctrl+Z doesn't delete files
func _create_location(title: String, area: AdventureArea, new_area_name: String, at: Vector2) -> void:
	if area == null:
		area = AdventureMapEditing.make_area(new_area_name)
		if not _create_file(area, AdventureMapEditing.get_area_path(adventure, new_area_name)): return
	var page: AdventurePage = AdventureMapEditing.make_location(title, area)
	if not _create_file(page, AdventureMapEditing.get_location_path(area, title)): return
	_layout.positions[AdventureLayout.get_key(page)] = at
	_save_layout()
	rebuild()

## Creates the event's file right away and lists it on [param location] (that part can be undone)
func _create_event(title: String, location: AdventurePage, scenario: bool) -> void:
	var event: AdventurePage = AdventureEventEditing.make_event(title, scenario)
	if not _create_file(event, AdventureEventEditing.get_event_path(location, title)): return
	var events: Array[AdventurePage] = location.events.duplicate()
	events.append(event)
	_undo_redo.create_action("Add %s to %s" % [title, AdventureGraph.get_title(location)], UndoRedo.MERGE_DISABLE, location)
	_change(location, &"events", events)
	_undo_redo.commit_action()

func _create_file(resource: Resource, path: String) -> bool:
	if FileAccess.file_exists(path):
		push_error("%s exists already" % path)
		return false
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	resource.take_over_path(path)
	if ResourceSaver.save(resource) != OK: return false
	EditorInterface.get_resource_filesystem().update_file(path)
	return true

func _on_property_edited(_property: String) -> void: rebuild()

func _save_layout() -> void:
	if adventure != null: _layout.save_for(adventure)
