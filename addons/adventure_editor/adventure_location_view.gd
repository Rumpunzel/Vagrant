@tool
class_name AdventureLocationView
extends VBoxContainer

## One location at a glance ([AdventureLocationOverview]): a section per source of events in its order (its own events, then the encounters
## that can show there), each with the events that could show and what they need; ▲ ▼ change the order; what can come here below.
## Double-click an event to open it.

signal event_opened(event: AdventureEvent, host: AdventurePage)
signal changes_requested(changes: Array[Array], action: String, file: Resource)

enum Move { UP, DOWN }

var _overview: AdventureLocationOverview
var _title: Label
var _tree: Tree

func setup() -> void:
	_title = Label.new()
	_title.theme_type_variation = &"HeaderMedium"
	add_child(_title)
	_tree = Tree.new()
	_tree.columns = 2
	_tree.hide_root = true
	_tree.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_tree.set_column_expand_ratio(0, 1)
	_tree.set_column_expand_ratio(1, 2)
	_tree.item_activated.connect(_on_item_activated)
	_tree.button_clicked.connect(_on_button_clicked)
	add_child(_tree)

func get_location() -> AdventureLocation: return _overview.location if _overview != null else null

## Shows [param location] (none: nothing); [param pages]: the map's pages, whose decisions may bring encounters here
func show_location(location: AdventureLocation, encounters: Array[AdventureEncounter], pages: Array[AdventurePage]) -> void:
	_tree.clear()
	_overview = AdventureLocationOverview.new(location, encounters, pages) if location != null else null
	_title.text = "Double-click a location on the map" if location == null else AdventureGraph.get_title(location)
	if _overview == null: return
	var root: TreeItem = _tree.create_item()
	for index: int in _overview.sections.size(): _add_section(root, index)
	if _overview.arrivals.is_empty(): return
	var arrivals: TreeItem = _tree.create_item(root)
	arrivals.set_text(0, "Can come here")
	arrivals.set_icon(0, _get_icon("MoveRight"))
	for arrival: AdventureLocationOverview.Arrival in _overview.arrivals:
		var item: TreeItem = _tree.create_item(arrivals)
		item.set_text(0, AdventureGraph.get_title(arrival.encounter))
		item.set_text(1, "%s: \"%s\"" % [AdventureGraph.get_title(arrival.page), arrival.decision.description.get_slice("\n", 0)])
		item.set_metadata(0, arrival.page if arrival.page is AdventureEvent else arrival.encounter)

func _add_section(root: TreeItem, index: int) -> void:
	var section: AdventureLocationOverview.Section = _overview.sections[index]
	var item: TreeItem = _tree.create_item(root)
	item.set_text(0, "%d · %s" % [index + 1, AdventureGraph.get_title(section.encounter) if section.encounter != null else "Its own events"])
	item.set_text(1, section.reason)
	item.set_icon(0, _get_icon("CharacterBody2D" if section.encounter != null else "Environment"))
	item.set_metadata(0, section.encounter)
	if index > 0: item.add_button(1, _get_icon("MoveUp"), Move.UP, false, "Earlier: shown first, Hide Below of earlier ones can hide it")
	if index < _overview.sections.size() - 1: item.add_button(1, _get_icon("MoveDown"), Move.DOWN, false, "Later")
	if section.events.is_empty():
		_tree.create_item(item).set_text(0, "(none)")
	for event: AdventureEvent in section.events:
		var row: TreeItem = _tree.create_item(item)
		row.set_text(0, AdventureGraph.get_title(event) + (" (near)" if event.where == AdventureEvent.Where.NEAR and section.encounter != null else ""))
		var needs: String = AdventureEventOverview.get_condition_text(event.conditions)
		row.set_text(1, "when %s" % needs if not needs.is_empty() else "")
		row.set_metadata(0, event)

func _on_item_activated() -> void:
	var event: AdventureEvent = _tree.get_selected().get_metadata(0) as AdventureEvent if _tree.get_selected() != null else null
	if event != null: event_opened.emit(event, get_location())

func _on_button_clicked(item: TreeItem, _column: int, id: int, _mouse_button: int) -> void:
	var index: int = item.get_index()
	var order: Array[String] = _overview.get_order_moving(index, -1 if id == Move.UP else 1)
	var changes: Array[Array] = [[_overview.location, &"order", order]]
	changes_requested.emit(changes, "Reorder %s" % AdventureGraph.get_title(_overview.location), _overview.location)

static func _get_icon(icon_name: String) -> Texture2D:
	return EditorInterface.get_editor_theme().get_icon(icon_name, &"EditorIcons") if Engine.is_editor_hint() else null
