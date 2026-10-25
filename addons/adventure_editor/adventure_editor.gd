@tool
class_name AdventureEditor
extends VBoxContainer

## Main screen of the adventure editor plugin: one adventure as a map ([AdventureMapView]) and its events ([AdventureEventView]).
## Only views for now: selecting opens the resource in the Inspector, moving nodes saves the [AdventureLayout].

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

## Called by the plugin, not in [method Node._ready], so opening this scene in the editor doesn't run it
func setup() -> void:
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
	_graph = AdventureGraph.new(adventure)
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

func _on_property_edited(_property: String) -> void: rebuild()

func _save_layout() -> void:
	if adventure != null: _layout.save_for(adventure)
