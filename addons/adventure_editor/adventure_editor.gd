@tool
class_name AdventureEditor
extends VBoxContainer

## Main screen of the adventure editor plugin: one adventure as a map ([AdventureMapView]) and its events ([AdventureEventView]).
## The graphs request edits to structure (links, new locations, areas, events, pages and decisions); [AdventureEdits] makes them, with undo,
## unsaved until [method save]. Content is edited in the Inspector: selecting opens the resource there. Moving nodes saves the [AdventureLayout] at once.

const INDENT: String = "    "

@export_group("Configuration")
@export var _picker: EditorResourcePicker
## Filters the event lists, jumps on Enter
@export var _find: LineEdit
@export var _tabs: TabContainer
@export var _map_tab: Control
@export var _map: AdventureMapView
## The map's sidebar of events to drag onto locations
@export var _event_shelf: VBoxContainer
## The "Problems" tab ([AdventureProblems])
@export var _problem_list: ItemList
@export var _events_tab: Control
@export var _event_list: ItemList
@export var _host_picker: OptionButton
@export var _event_view: AdventureEventView

var adventure: Adventure : set = set_adventure

var _graph: AdventureGraph
var _problems: Array[AdventureProblems.Problem] = [ ]
var _layout: AdventureLayout
var _edits: AdventureEdits
## Every event of the adventure, found once per rebuild ([method _find_all_events])
var _all_events: Array[AdventurePage] = [ ]
var _new_location_dialog: AdventureNewLocationDialog
var _name_dialog: AdventureNameDialog
var _file_dialog: EditorFileDialog
var _delete_dialog: ConfirmationDialog

## Called by the plugin, not in [method Node._ready], so opening this scene in the editor doesn't run it
func setup(undo_redo: EditorUndoRedoManager) -> void:
	_edits = AdventureEdits.new(undo_redo)
	_edits.changed.connect(rebuild)
	_map.setup()
	_event_view.setup()
	_make_dialogs()
	_connect_views()
	_connect_lists()
	EditorInterface.get_inspector().property_edited.connect(_on_property_edited)

func _make_dialogs() -> void:
	_new_location_dialog = AdventureNewLocationDialog.new()
	_new_location_dialog.location_confirmed.connect(_create_location)
	add_child(_new_location_dialog)
	_name_dialog = AdventureNameDialog.new()
	add_child(_name_dialog)
	_file_dialog = EditorFileDialog.new()
	_file_dialog.file_mode = EditorFileDialog.FILE_MODE_OPEN_FILE
	_file_dialog.add_filter("*.tres", "Events")
	add_child(_file_dialog)
	_delete_dialog = ConfirmationDialog.new()
	_delete_dialog.ok_button_text = "Delete"
	add_child(_delete_dialog)

func _connect_views() -> void:
	for view: AdventureGraphView in [_map, _event_view]:
		view.changes_requested.connect(_edits.apply)
		view.event_opened.connect(open_event)
		view.layout_changed.connect(_save_layout)
		view.tidied.connect(rebuild)
		view.play_requested.connect(_play_from)
		view.deletion_requested.connect(_ask_to_delete)
	_map.location_requested.connect(_ask_for_location)
	_map.event_requested.connect(func(location: AdventurePage, scenario: bool) -> void:
		_name_dialog.ask("New scenario" if scenario else "New event", "Title", _create_event.bind(location, scenario))
	)
	_map.existing_event_requested.connect(_offer_events)
	_event_view.exit_opened.connect(_open_location)
	_event_view.nearby_event_requested.connect(_offer_nearby_events)
	_event_view.option_requested.connect(func(scenario: AdventureEventScenario) -> void: _name_dialog.ask("New option", "Title", _create_event.bind(scenario, false)))

func _connect_lists() -> void:
	_picker.resource_changed.connect(func(resource: Resource) -> void: set_adventure(resource as Adventure))
	_event_list.item_selected.connect(func(index: int) -> void: _show_event(_event_list.get_item_metadata(index) as AdventurePage, null))
	_host_picker.item_selected.connect(func(index: int) -> void: _event_view.show_event(_event_view.get_event(), _host_picker.get_item_metadata(index) as AdventurePage))
	_problem_list.item_selected.connect(_show_problem)
	_find.text_changed.connect(func(_text: String) -> void:
		_list_events()
		_fill_event_shelf()
	)
	_find.text_submitted.connect(_jump_to)

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
	_all_events = _find_all_events()
	_problems = [ ]
	if adventure != null: _problems = AdventureProblems.new(_graph, _all_events).problems
	_map.problems = _problems
	_event_view.problems = _problems
	_map.show_graph(_graph)
	var listed: Array[AdventurePage] = _list_events()
	_fill_event_shelf()
	_list_problems()
	var current: AdventurePage = _event_view.get_event()
	if listed.has(current): _show_event(current, _event_view.get_host())
	else: _show_event(null, null)

## Shows [param event] in the events tab, at [param host] if given
func open_event(event: AdventurePage, host: AdventurePage) -> void:
	_tabs.current_tab = _tabs.get_tab_idx_from_control(_events_tab)
	_show_event(event, host)
	_event_view.scroll_to_nodes()

## Scenarios list their options below them, events the sub-events of their pages
## Every event met, as a tree; returns them all, shown or filtered out
func _list_events() -> Array[AdventurePage]:
	_event_list.clear()
	var listed: Array[AdventurePage] = [ ]
	if _graph != null: for event: AdventurePage in _graph.get_top_events(): _list_event(event, 0, listed)
	return listed

## Those not fitting the find field are left out, their sub-events are still looked at
func _list_event(event: AdventurePage, depth: int, listed: Array[AdventurePage]) -> void:
	if listed.has(event): return
	listed.append(event)
	if _fits(event):
		var index: int = _event_list.add_item(INDENT.repeat(depth) + _describe_event(event))
		_event_list.set_item_metadata(index, event)
		_event_list.set_item_tooltip(index, event.resource_path)
	var nested: Array[AdventurePage] = event.events.duplicate()
	nested.append_array(event.nearby_events)
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
	_tabs.current_tab = _tabs.get_tab_idx_from_control(_map_tab)
	_map.focus_page(location)

func has_unsaved_changes() -> bool: return _edits.has_unsaved_changes()

func save() -> void: _edits.save()

## Ctrl+S saves, Ctrl+F finds
func _shortcut_input(input: InputEvent) -> void:
	var key: InputEventKey = input as InputEventKey
	if not is_visible_in_tree() or key == null or not key.pressed or not key.is_command_or_control_pressed() or key.shift_pressed: return
	if key.keycode == KEY_S and has_unsaved_changes(): save()
	elif key.keycode == KEY_F:
		_find.grab_focus()
		_find.select_all()
	else: return
	get_viewport().set_input_as_handled()

## Whether [param page]'s title fits the find field (everything fits an empty one)
func _fits(page: AdventurePage) -> bool:
	return _find.text.strip_edges().is_empty() or AdventureGraph.get_title(page).to_lower().contains(_find.text.strip_edges().to_lower())

## The first location on the map whose title fits, else the first event
func _jump_to(_text: String) -> void:
	if _find.text.strip_edges().is_empty() or _graph == null: return
	for page: AdventurePage in _graph.pages:
		if _fits(page):
			_open_location(page)
			return
	for event: AdventurePage in _all_events:
		if _fits(event):
			open_event(event, null)
			return
	push_warning("Nothing called \"%s\"" % _find.text)

func _ask_for_location(at: Vector2) -> void:
	if adventure != null: _new_location_dialog.open(_graph.areas, at)

## Creates the location's file (and a new area's) right away; Ctrl+Z doesn't delete files
## Its file (and a new area's) is part of the undo step
func _create_location(title: String, area: AdventureArea, new_area_name: String, at: Vector2) -> void:
	var files: Dictionary[String, Resource] = {}
	if area == null:
		area = AdventureMapEditing.make_area(new_area_name)
		area.resource_path = AdventureMapEditing.get_area_path(adventure, new_area_name)
		files[area.resource_path] = area
	var page: AdventurePage = AdventureMapEditing.make_location(title, area)
	var path: String = AdventureMapEditing.get_location_path(area, title)
	files[path] = page
	var changes: Array[Array] = [ ]
	if not _edits.create(files, changes, "New location %s" % title): return
	_layout.positions[AdventureLayout.get_key(page)] = at
	_save_layout()
	rebuild()

## The adventure's events (those met and every file in an events folder) not on [param location] yet, and any other file
func _offer_events(location: AdventurePage) -> void:
	_offer(location.events, func(event: AdventurePage) -> void: _map.add_event(location, event), _map)

## For "Add nearby event…": shown around [param event]'s locations
func _offer_nearby_events(event: AdventurePage) -> void:
	var taken: Array[AdventurePage] = event.nearby_events.duplicate()
	taken.append(event)
	_offer(taken, _add_nearby_event.bind(event), _event_view)

func _add_nearby_event(nearby: AdventurePage, event: AdventurePage) -> void:
	var nearby_events: Array[AdventurePage] = event.nearby_events.duplicate()
	nearby_events.append(nearby)
	var changes: Array[Array] = [[event, &"nearby_events", nearby_events]]
	_edits.apply(changes, "Add nearby %s" % AdventureGraph.get_title(nearby), load(AdventureEventEditing.get_file_path(event)))

## A menu of the adventure's events (those met and every file in an events folder) but [param taken], and any other file; [param on_pick] gets the event
func _offer(taken: Array, on_pick: Callable, view: AdventureGraphView) -> void:
	var events: Array[AdventurePage] = _all_events
	var actions: Dictionary[String, Callable] = {}
	for event: AdventurePage in events:
		if not taken.has(event): actions[_describe_event(event)] = on_pick.bind(event)
	actions["Other file…"] = func() -> void:
		for connection: Dictionary in _file_dialog.file_selected.get_connections(): _file_dialog.file_selected.disconnect(connection["callable"])
		_file_dialog.file_selected.connect(func(path: String) -> void:
			var event: AdventurePage = load(path) as AdventurePage
			if event != null: on_pick.call(event)
			else: push_warning("%s is no page or event" % path)
		)
		_file_dialog.popup_file_dialog()
	view.show_actions(actions)

## The events met on the map and every event file in an events folder under the adventure; not those stored inside other files
func _find_all_events() -> Array[AdventurePage]:
	var events: Array[AdventurePage] = [ ]
	events.assign(_graph.event_hosts.keys())
	if adventure != null:
		for path: String in AdventureEventEditing.find_event_files(adventure.resource_path.get_base_dir()):
			var event: AdventurePage = load(path) as AdventurePage
			if event != null and not events.has(event): events.append(event)
	return events.filter(func(event: AdventurePage) -> bool: return not AdventureEventEditing.is_inside_file(event))

static func _describe_event(event: AdventurePage) -> String:
	return AdventureGraph.get_title(event) + (" (scenario)" if event is AdventureEventScenario else "")

## The sidebar's events: drag one onto a location, press one to open it
func _fill_event_shelf() -> void:
	for button: Node in _event_shelf.get_children(): button.queue_free()
	for event: AdventurePage in _all_events:
		if not _fits(event): continue
		var button: AdventureEventButton = AdventureEventButton.new()
		button.event = event
		button.text = _describe_event(event)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		button.tooltip_text = "%s\nDrag onto a location to list it there; press to open it" % event.resource_path
		button.pressed.connect(open_event.bind(event, null))
		_event_shelf.add_child(button)

## Saves, then starts the game at [param page]: a location as it is; an event's own page at its host (the picked one, else the first), so it shows
## if its conditions fit; a page behind an event on that page, with the host entered before it
func _play_from(page: AdventurePage, event: AdventurePage) -> void:
	var host: AdventurePage = null
	if event != null:
		host = _event_view.get_host()
		var hosts: Array[AdventurePage] = _graph.get_location_hosts(event)
		if host == null and not hosts.is_empty(): host = hosts[0]
		if host == null:
			push_warning("%s is listed on no location, so there is nowhere to show it" % AdventureGraph.get_title(event))
			return
		if page == event: page = host
	save()
	AdventurePlayFrom.write(adventure, page, host)
	EditorInterface.play_main_scene()

func _list_problems() -> void:
	_problem_list.clear()
	var problems: Array[AdventureProblems.Problem] = _problems
	for problem: AdventureProblems.Problem in problems:
		_problem_list.set_item_metadata(_problem_list.add_item(problem.text), problem)
	var index: int = _tabs.get_tab_idx_from_control(_problem_list)
	_tabs.set_tab_title(index, "Problems (%d)" % problems.size() if not problems.is_empty() else "Problems")

## Opens where the problem is: the event (or the map) with its page in the middle
func _show_problem(index: int) -> void:
	var problem: AdventureProblems.Problem = _problem_list.get_item_metadata(index)
	if problem.event == null:
		_open_location(problem.page)
		return
	open_event(problem.event, null)
	_event_view.focus_resource.call_deferred(problem.page)

## Creates the event's file right away and lists it on [param location] (that part can be undone)
func _create_event(title: String, location: AdventurePage, scenario: bool) -> void:
	var event: AdventurePage = AdventureEventEditing.make_event(title, scenario)
	var files: Dictionary[String, Resource] = {AdventureEventEditing.get_event_path(location, title): event}
	var events: Array[AdventurePage] = location.events.duplicate()
	events.append(event)
	var changes: Array[Array] = [[location, &"events", events, load(AdventureEventEditing.get_file_path(location))]]
	_edits.create(files, changes, "New %s on %s" % [title, AdventureGraph.get_title(location)])

## Asks first; the starting page can't go
func _ask_to_delete(resource: Resource) -> void:
	if resource == adventure.starting_page:
		push_warning("The starting page can't be deleted; set another one on the adventure first")
		return
	var title: String = AdventureGraph.get_title(resource as AdventurePage) if resource is AdventurePage else (resource as AdventureArea).name
	_delete_dialog.dialog_text = "Delete %s?\nWhat points to it is removed (Ctrl+Z brings that back); its file goes to the system trash." % title
	for connection: Dictionary in _delete_dialog.confirmed.get_connections(): _delete_dialog.confirmed.disconnect(connection["callable"])
	_delete_dialog.confirmed.connect(_delete.bind(resource, title))
	_delete_dialog.popup_centered()

func _delete(resource: Resource, title: String) -> void:
	var changes: Array[Array] = [ ]
	if resource is AdventureArea: changes = AdventureEventEditing.get_changes_forgetting_area(resource as AdventureArea, _graph.pages)
	else:
		var roots: Array[AdventurePage] = _graph.pages.duplicate()
		for event: AdventurePage in _all_events: if not roots.has(event): roots.append(event)
		changes = AdventureEventEditing.get_changes_forgetting(resource as AdventurePage, roots)
	_edits.delete(resource, changes, "Delete %s" % title)

func _on_property_edited(_property: String) -> void: rebuild()

func _save_layout() -> void:
	if adventure != null: _layout.save_for(adventure)
