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
## Where the event screen goes, next to the special nodes' sidebar
@export var _event_body: HBoxContainer

var adventure: Adventure : set = set_adventure

var _graph: AdventureGraph
var _problems: Array[AdventureProblems.Problem] = [ ]
var _layout: AdventureLayout
var _edits: AdventureEdits
## Every event of the adventure, found once per rebuild ([method _find_all_events])
var _all_events: Array[AdventureEvent] = [ ]
var _new_location_dialog: AdventureNewLocationDialog
var _name_dialog: AdventureNameDialog
var _file_dialog: EditorFileDialog
var _delete_dialog: ConfirmationDialog
var _profile_dialog: EditorFileDialog
var _location_view: AdventureLocationView
var _event_screen: AdventureEventScreen

## Called by the plugin, not in [method Node._ready], so opening this scene in the editor doesn't run it
func setup(undo_redo: EditorUndoRedoManager) -> void:
	_edits = AdventureEdits.new(undo_redo)
	_edits.changed.connect(rebuild)
	_map.setup()
	_make_dialogs()
	_make_location_tab()
	_make_event_screen()
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
	_profile_dialog = EditorFileDialog.new()
	_profile_dialog.file_mode = EditorFileDialog.FILE_MODE_OPEN_FILE
	_profile_dialog.title = "Monster profile"
	_profile_dialog.add_filter("*.tres", "Monster profiles")
	_profile_dialog.current_dir = "res://characters/monsters"
	add_child(_profile_dialog)
	_delete_dialog = ConfirmationDialog.new()
	_delete_dialog.ok_button_text = "Delete"
	add_child(_delete_dialog)

## Built here rather than in the scene: a tab after the map
func _make_location_tab() -> void:
	_location_view = AdventureLocationView.new()
	_location_view.name = "Location"
	_location_view.setup()
	_tabs.add_child(_location_view)
	_tabs.move_child(_location_view, _map_tab.get_index() + 1)

## Built here: the screen of the event shown, before the special nodes' sidebar
func _make_event_screen() -> void:
	_event_screen = AdventureEventScreen.new()
	_event_screen.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_event_screen.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_event_body.add_child(_event_screen)
	_event_body.move_child(_event_screen, 0)
	_event_screen.setup()
	_event_screen.make_graph = _make_event_graph

## A page graph for a section of the event screen, wired up like the map
func _make_event_graph() -> AdventureEventView:
	var graph: AdventureEventView = AdventureEventView.new()
	graph.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	graph.layout = _layout
	graph.problems = _problems
	graph.encounters = _get_encounters()
	graph.changes_requested.connect(_edits.apply)
	graph.event_opened.connect(open_event)
	graph.layout_changed.connect(_save_layout)
	graph.tidied.connect(rebuild)
	graph.play_requested.connect(_play_from)
	graph.deletion_requested.connect(_ask_to_delete)
	graph.exit_opened.connect(_open_location)
	return graph

## Events made already (and any other file) as the last option of [param scenario]
func _offer_options(scenario: AdventureEventScenario, show_actions: Callable) -> void:
	var taken: Array = scenario.events.duplicate()
	taken.append(scenario)
	_offer(taken, _add_option.bind(scenario), show_actions)

func _add_option(event: AdventureEvent, scenario: AdventureEventScenario) -> void:
	var options: Array[AdventureEvent] = scenario.events.duplicate()
	options.append(event)
	_edits.apply(AdventureEventEditing.get_changes_listing(scenario, options), "Add %s to %s" % [AdventureGraph.get_title(event), AdventureGraph.get_title(scenario)])

## The scenario or encounter (a file of its own, not a location's own events) [param event] is an option of, if any
func _find_scenario_of(event: AdventureEvent) -> AdventureEventScenario:
	for host: AdventurePage in _graph.get_hosts(event):
		if host is AdventureEventScenario and not AdventureEventEditing.is_inside_file(host): return host as AdventureEventScenario
	return null

func _show_location(location: AdventureLocation) -> void:
	_tabs.current_tab = _tabs.get_tab_idx_from_control(_location_view)
	_location_view.show_location(location, _get_encounters(), _graph.pages)

func _get_encounters() -> Array[AdventureEncounter]:
	var encounters: Array[AdventureEncounter] = [ ]
	if adventure != null: for encounter: AdventureEncounter in adventure.encounters: if encounter != null: encounters.append(encounter)
	return encounters

func _connect_views() -> void:
	for view: AdventureGraphView in [_map]:
		view.changes_requested.connect(_edits.apply)
		view.event_opened.connect(open_event)
		view.layout_changed.connect(_save_layout)
		view.tidied.connect(rebuild)
		view.play_requested.connect(_play_from)
		view.deletion_requested.connect(_ask_to_delete)
	_map.location_requested.connect(_ask_for_location)
	_map.event_requested.connect(_ask_for_event)
	_map.existing_event_requested.connect(func(location: AdventureLocation) -> void: _offer_events(location, _map.show_actions))
	_map.encounter_requested.connect(_ask_for_encounter)
	_map.location_opened.connect(_show_location)
	_location_view.event_opened.connect(open_event)
	_location_view.changes_requested.connect(_edits.apply)
	_location_view.event_requested.connect(_ask_for_event)
	_location_view.existing_event_requested.connect(_offer_events)
	_location_view.encounter_requested.connect(_ask_for_encounter)
	_event_screen.option_requested.connect(func(scenario: AdventureEventScenario) -> void: _name_dialog.ask("New option", "Title", _create_event.bind(scenario, false)))
	_event_screen.existing_option_requested.connect(_offer_options)
	_event_screen.event_opened.connect(open_event)
	_event_screen.changes_requested.connect(_edits.apply)
	_event_screen.text_requested.connect(_name_dialog.ask)

func _connect_lists() -> void:
	_picker.resource_changed.connect(func(resource: Resource) -> void: set_adventure(resource as Adventure))
	_event_list.item_selected.connect(func(index: int) -> void: _show_event(_event_list.get_item_metadata(index) as AdventureEvent, null))
	_host_picker.item_selected.connect(func(index: int) -> void: _show_event(_event_screen.get_event(), _host_picker.get_item_metadata(index) as AdventurePage))
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
	_event_screen.show_event(null, null)
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
	_map.show_graph(_graph)
	var listed: Array[AdventureEvent] = _list_events()
	_fill_event_shelf()
	_list_problems()
	var shown: AdventureLocation = _location_view.get_location()
	_location_view.show_location(shown if _graph.pages.has(shown) else null, _get_encounters(), _graph.pages)
	var current: AdventureEvent = _event_screen.get_event()
	if listed.has(current): _show_event(current, _event_screen.get_host())
	else: _show_event(null, null)

## Shows [param event] in the events tab, at [param host] if given
func open_event(event: AdventureEvent, host: AdventurePage) -> void:
	_tabs.current_tab = _tabs.get_tab_idx_from_control(_events_tab)
	_show_event(event, host)

## Scenarios list their options below them, events the sub-events of their pages
## Every event met, as a tree; returns them all, shown or filtered out
func _list_events() -> Array[AdventureEvent]:
	_event_list.clear()
	var listed: Array[AdventureEvent] = [ ]
	if _graph != null: for event: AdventureEvent in _graph.get_top_events(): _list_event(event, 0, listed)
	return listed

## Those not fitting the find field are left out; options show on their scenario's or encounter's screen, so they are listed (below it) only
## while finding
func _list_event(event: AdventureEvent, depth: int, listed: Array[AdventureEvent]) -> void:
	if listed.has(event): return
	listed.append(event)
	if _fits(event):
		var index: int = _event_list.add_item(INDENT.repeat(depth) + _describe_event(event))
		_event_list.set_item_metadata(index, event)
		_event_list.set_item_tooltip(index, event.resource_path)
	if _find.text.strip_edges().is_empty(): return
	for sub_event: AdventureEvent in AdventureGraph.get_listed_on(event): _list_event(sub_event, depth + 1, listed)

## An option of a scenario or encounter shows on its screen, unfolded
func _show_event(event: AdventureEvent, host: AdventurePage) -> void:
	var scenario: AdventureEventScenario = _find_scenario_of(event) if event != null and _graph != null else null
	_event_screen.show_event(scenario if scenario != null else event, host, event if scenario != null else null)
	_event_list.deselect_all()
	for index: int in _event_list.item_count:
		if _event_list.get_item_metadata(index) == event: _event_list.select(index)
	_host_picker.clear()
	_host_picker.add_item("At any host")
	_host_picker.set_item_metadata(0, null)
	if event == null: return
	for location: AdventureLocation in _graph.get_location_hosts(event):
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
	for event: AdventureEvent in _all_events:
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

func _ask_for_event(location: AdventureLocation, scenario: bool) -> void:
	_name_dialog.ask("New scenario" if scenario else "New event", "Title", _create_event.bind(location, scenario))

## The adventure's events (those met and every file in an events folder) not on [param location] yet, and any other file;
## [param show_actions] shows the menu
func _offer_events(location: AdventureLocation, show_actions: Callable) -> void:
	_offer(location.get_own_events(), func(event: AdventureEvent) -> void: _map.put_event(location, event), show_actions)

## A menu of the adventure's events (those met and every file in an events folder) but [param taken], and any other file; [param on_pick] gets the event
func _offer(taken: Array, on_pick: Callable, show_actions: Callable) -> void:
	var events: Array[AdventureEvent] = _all_events
	var actions: Dictionary[String, Callable] = {}
	for event: AdventureEvent in events:
		if not taken.has(event): actions[_describe_event(event)] = on_pick.bind(event)
	actions["Other file…"] = func() -> void:
		for connection: Dictionary in _file_dialog.file_selected.get_connections(): _file_dialog.file_selected.disconnect(connection["callable"])
		_file_dialog.file_selected.connect(func(path: String) -> void:
			var event: AdventureEvent = load(path) as AdventureEvent
			if event != null: on_pick.call(event)
			else: push_warning("%s is no event" % path)
		)
		_file_dialog.popup_file_dialog()
	show_actions.call(actions)

## The events met on the map and every event file in an events folder under the adventure; not those stored inside other files
func _find_all_events() -> Array[AdventureEvent]:
	var events: Array[AdventureEvent] = [ ]
	events.assign(_graph.event_hosts.keys())
	if adventure != null:
		for path: String in AdventureEventEditing.find_event_files(adventure.resource_path.get_base_dir()):
			var event: AdventureEvent = load(path) as AdventureEvent
			if event != null and not events.has(event): events.append(event)
	return events.filter(func(event: AdventureEvent) -> bool: return not AdventureEventEditing.is_inside_file(event))

static func _describe_event(event: AdventureEvent) -> String:
	var kind: String = " (encounter)" if event is AdventureEncounter else " (scenario)" if event is AdventureEventScenario else ""
	return AdventureGraph.get_title(event) + kind

## The sidebar's events: drag one onto a location, press one to open it
func _fill_event_shelf() -> void:
	for button: Node in _event_shelf.get_children(): button.queue_free()
	for event: AdventureEvent in _all_events:
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
func _play_from(page: AdventurePage, event: AdventureEvent) -> void:
	var host: AdventurePage = null
	if event != null:
		host = _event_screen.get_host()
		var hosts: Array[AdventureLocation] = _graph.get_location_hosts(event)
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
	_event_screen.focus_resource.call_deferred(problem.page)

## Creates the event's file and lists it on [param host] (a location, or a scenario as its last option), as one undo step
func _create_event(title: String, host: AdventurePage, scenario: bool) -> void:
	var event: AdventureEvent = AdventureEventEditing.make_event(title, scenario)
	var files: Dictionary[String, Resource] = {AdventureEventEditing.get_event_path(host, title): event}
	var events: Array[AdventureEvent] = AdventureGraph.get_listed_on(host)
	events.append(event)
	_edits.create(files, AdventureEventEditing.get_changes_listing(host, events), "New %s on %s" % [title, AdventureGraph.get_title(host)])

## An NPC is named in a dialog; a monster is named after its profile (asked for if not given)
func _ask_for_encounter(location: AdventureLocation, monster: bool, profile: MonsterProfile) -> void:
	if not monster:
		_name_dialog.ask("New encounter", "Name", func(title: String) -> void: _create_encounter(title, location, null))
		return
	if profile != null:
		_create_encounter(profile.name, location, profile)
		return
	for connection: Dictionary in _profile_dialog.file_selected.get_connections(): _profile_dialog.file_selected.disconnect(connection["callable"])
	_profile_dialog.file_selected.connect(func(path: String) -> void:
		var picked: MonsterProfile = load(path) as MonsterProfile
		if picked != null: _create_encounter(picked.name, location, picked)
		else: push_warning("%s is no monster profile" % path)
	)
	_profile_dialog.popup_file_dialog()

## Its files and its place in the adventure's encounters, as one undo step
func _create_encounter(title: String, location: AdventureLocation, profile: MonsterProfile) -> void:
	var files: Dictionary[String, Resource] = AdventureEventEditing.make_encounter_files(adventure, title, location, profile)
	var encounters: Array[AdventureEncounter] = adventure.encounters.duplicate()
	encounters.append(files.values().back() as AdventureEncounter)
	_edits.create(files, [[adventure, &"encounters", encounters, adventure]] as Array[Array], "New encounter %s" % title)

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
		for event: AdventureEvent in _all_events: if not roots.has(event): roots.append(event)
		changes = AdventureEventEditing.get_changes_forgetting(resource as AdventurePage, roots)
	var key: String = AdventureLayout.get_key(resource)
	if adventure.encounters.has(resource):
		var encounters: Array[AdventureEncounter] = adventure.encounters.duplicate()
		encounters.erase(resource)
		changes.append([adventure, &"encounters", encounters, adventure])
	_edits.delete(resource, changes, "Delete %s" % title)
	_layout.positions.erase(key)
	_save_layout()

func _on_property_edited(_property: String) -> void: rebuild()

func _save_layout() -> void:
	if adventure != null: _layout.save_for(adventure)
