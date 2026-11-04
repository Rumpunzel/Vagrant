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
var _tooltips: AdventureTooltips
var _layout: AdventureLayout
var _edits: AdventureEdits
## Every event of the adventure, found once per rebuild ([method _find_all_events])
var _all_events: Array[AdventureEvent] = [ ]
var _location_view: AdventureLocationView
var _event_screen: AdventureEventScreen
var _actions: AdventureEditorActions

## Called by the plugin, not in [method Node._ready], so opening this scene in the editor doesn't run it
func setup(undo_redo: EditorUndoRedoManager) -> void:
	_edits = AdventureEdits.new(undo_redo)
	_edits.changed.connect(rebuild)
	_map.setup()
	_actions = AdventureEditorActions.new()
	add_child(_actions)
	_actions.setup(self)
	_make_location_panel()
	_make_event_screen()
	_connect_views()
	_connect_lists()
	EditorInterface.get_inspector().property_edited.connect(_on_property_edited)

## Built here rather than in the scene: the panel left of the map, hidden until a location is selected
func _make_location_panel() -> void:
	_location_view = AdventureLocationView.new()
	_location_view.name = "Location"
	_location_view.setup()
	_location_view.hide()
	_map_tab.add_child(_location_view)
	_map_tab.move_child(_location_view, 0)

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
	graph.tooltips = _tooltips
	graph.encounters = _get_encounters()
	graph.changes_requested.connect(_edits.apply)
	graph.event_opened.connect(open_event)
	graph.layout_changed.connect(save_layout)
	graph.tidied.connect(rebuild)
	graph.play_requested.connect(_play_from)
	graph.deletion_requested.connect(_actions.ask_to_delete)
	graph.exit_opened.connect(_open_location)
	return graph

## The scenario or encounter (a file of its own, not a location's own events) [param event] is an option of, if any
func _find_scenario_of(event: AdventureEvent) -> AdventureEventScenario:
	for host: AdventurePage in _graph.get_hosts(event):
		if host is AdventureEventScenario and not AdventureEventEditing.is_inside_file(host): return host as AdventureEventScenario
	return null

func _show_location(location: AdventureLocation) -> void:
	_location_view.show_location(location, _get_encounters(), _graph.pages)

func _get_encounters() -> Array[AdventureEncounter]:
	var encounters: Array[AdventureEncounter] = [ ]
	if adventure != null: for encounter: AdventureEncounter in adventure.encounters: if encounter != null: encounters.append(encounter)
	return encounters

func _connect_views() -> void:
	for view: AdventureGraphView in [_map]:
		view.changes_requested.connect(_edits.apply)
		view.event_opened.connect(open_event)
		view.layout_changed.connect(save_layout)
		view.tidied.connect(rebuild)
		view.play_requested.connect(_play_from)
		view.deletion_requested.connect(_actions.ask_to_delete)
	_map.location_requested.connect(_actions.ask_for_location)
	_map.event_requested.connect(_actions.ask_for_event)
	_map.existing_event_requested.connect(func(location: AdventureLocation) -> void: _actions.offer_events(location, _map.show_actions))
	_map.encounter_requested.connect(_actions.ask_for_encounter)
	_map.location_selected.connect(_show_location)
	_location_view.event_opened.connect(open_event)
	_location_view.changes_requested.connect(_edits.apply)
	_location_view.event_requested.connect(_actions.ask_for_event)
	_location_view.existing_event_requested.connect(_actions.offer_events)
	_location_view.encounter_requested.connect(_actions.ask_for_encounter)
	_event_screen.option_requested.connect(_actions.ask_for_option)
	_event_screen.existing_option_requested.connect(_actions.offer_options)
	_event_screen.event_opened.connect(open_event)
	_event_screen.changes_requested.connect(_edits.apply)
	_event_screen.text_requested.connect(_actions.ask_name)
	_event_screen.play_requested.connect(_play_from)
	_location_view.play_requested.connect(_play_from)

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
	_tooltips = AdventureTooltips.new(_graph)
	_tooltips.problems = _problems
	_tooltips.opened.connect(_open_resource)
	_map.tooltips = _tooltips
	_event_screen.tooltips = _tooltips
	_location_view.tooltips = _tooltips
	_map.show_graph(_graph)
	var listed: Array[AdventureEvent] = _list_events()
	_fill_event_shelf()
	_list_problems()
	var shown: AdventureLocation = _location_view.get_location() if _location_view.visible else null
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
		var index: int = _event_list.add_item(INDENT.repeat(depth) + describe_event(event))
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

## What a tooltip's link names: an event on its screen, a page on the map
func _open_resource(resource: Resource) -> void:
	if resource is AdventureEvent: open_event(resource as AdventureEvent, null)
	elif resource is AdventurePage: _open_location(resource as AdventurePage)

func _open_location(location: AdventurePage) -> void:
	_tabs.current_tab = _tabs.get_tab_idx_from_control(_map_tab)
	_map.focus_page(location)
	if location is AdventureLocation: _show_location(location as AdventureLocation)

func get_edits() -> AdventureEdits: return _edits

func get_graph() -> AdventureGraph: return _graph

## Every event of the adventure ([method _find_all_events])
func get_all_events() -> Array[AdventureEvent]: return _all_events

func get_layout() -> AdventureLayout: return _layout

func get_map() -> AdventureMapView: return _map

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

## The events met on the map and every event file in an events folder under the adventure; not those stored inside other files
func _find_all_events() -> Array[AdventureEvent]:
	var events: Array[AdventureEvent] = [ ]
	events.assign(_graph.event_hosts.keys())
	if adventure != null:
		for path: String in AdventureEventEditing.find_event_files(adventure.resource_path.get_base_dir()):
			var event: AdventureEvent = load(path) as AdventureEvent
			if event != null and not events.has(event): events.append(event)
	return events.filter(func(event: AdventureEvent) -> bool: return not AdventureEventEditing.is_inside_file(event))

static func describe_event(event: AdventureEvent) -> String:
	var kind: String = " (encounter)" if event is AdventureEncounter else " (scenario)" if event is AdventureEventScenario else ""
	return AdventureGraph.get_title(event) + kind

## The sidebar's events: drag one onto a location, press one to open it. Options of an encounter or scenario come with it, so they aren't offered alone
func _fill_event_shelf() -> void:
	for button: Node in _event_shelf.get_children(): button.queue_free()
	var options: Array[AdventureEvent] = [ ]
	for event: AdventureEvent in _all_events: if event is AdventureEventScenario: options.append_array((event as AdventureEventScenario).events)
	for event: AdventureEvent in _all_events:
		if options.has(event) or not _fits(event): continue
		var button: AdventureEventButton = AdventureEventButton.new()
		button.event = event
		button.icon = AdventureActionMenu.get_event_icon(event)
		button.add_theme_constant_override(&"icon_max_width", AdventureActionMenu.ICON_SIZE)
		button.text = describe_event(event)
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
	AdventurePlayFrom.write(adventure, page, host, event)
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

func _on_property_edited(_property: String) -> void: rebuild()

func save_layout() -> void:
	if adventure != null: _layout.save_for(adventure)
