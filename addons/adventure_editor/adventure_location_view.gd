@tool
class_name AdventureLocationView
extends VBoxContainer

## One location at a glance ([AdventureLocationOverview]): a section per source of events in its order (its own events, then the encounters
## that can show there), each with the events that could show and what they need; what can come here below. ▲ ▼ change the order, + adds
## events or encounters, ✕ takes them off here. Selecting a row shows it in the Inspector; double-click an event to open it.

signal event_opened(event: AdventureEvent, host: AdventurePage)
signal changes_requested(changes: Array[Array], action: String, file: Resource)
## A new event (or scenario) among [param location]'s own events
signal event_requested(location: AdventureLocation, scenario: bool)
## Pick an event made already for [param location]'s own events; [param show_actions] shows the choices
signal existing_event_requested(location: AdventureLocation, show_actions: Callable)
signal encounter_requested(location: AdventureLocation, monster: bool, profile: MonsterProfile)

enum Act { UP, DOWN, ADD, REMOVE }

var _overview: AdventureLocationOverview
var _encounters: Array[AdventureEncounter] = [ ]
var _title: Label
var _tree: Tree
var _menu: AdventureActionMenu

func setup() -> void:
	var bar: HBoxContainer = HBoxContainer.new()
	add_child(bar)
	_title = Label.new()
	_title.theme_type_variation = &"HeaderMedium"
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.add_child(_title)
	var add: Button = Button.new()
	add.text = "Encounter"
	add.icon = AdventureActionMenu.get_editor_icon("Add")
	add.tooltip_text = "A new encounter here, or one made already"
	add.pressed.connect(_on_add_encounter)
	bar.add_child(add)
	_tree = Tree.new()
	_tree.columns = 2
	_tree.hide_root = true
	_tree.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_tree.set_column_expand_ratio(0, 1)
	_tree.set_column_expand_ratio(1, 2)
	_tree.item_activated.connect(_on_item_activated)
	_tree.item_selected.connect(_on_item_selected)
	_tree.button_clicked.connect(_on_button_clicked)
	add_child(_tree)
	_menu = AdventureActionMenu.new()
	add_child(_menu)

func _on_add_encounter() -> void:
	if get_location() != null: _menu.show_actions(_get_encounter_actions())

func get_location() -> AdventureLocation: return _overview.location if _overview != null else null

## Shows [param location] (none: nothing); [param pages]: the map's pages, whose decisions may bring encounters here
func show_location(location: AdventureLocation, encounters: Array[AdventureEncounter], pages: Array[AdventurePage]) -> void:
	_tree.clear()
	_encounters = encounters
	_overview = AdventureLocationOverview.new(location, encounters, pages) if location != null else null
	_title.text = "Double-click a location on the map" if location == null else AdventureGraph.get_title(location)
	if _overview == null: return
	var root: TreeItem = _tree.create_item()
	for index: int in _overview.sections.size(): _add_section(root, index)
	if _overview.arrivals.is_empty(): return
	var arrivals: TreeItem = _tree.create_item(root)
	arrivals.set_text(0, "Can come here")
	arrivals.set_icon(0, AdventureActionMenu.get_editor_icon("MoveRight"))
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
	item.set_icon(0, AdventureActionMenu.get_editor_icon("CharacterBody2D" if section.encounter != null else "Environment"))
	item.set_metadata(0, section.encounter if section.encounter != null else _overview.location)
	if index > 0: item.add_button(1, AdventureActionMenu.get_editor_icon("MoveUp"), Act.UP, false, "Earlier: shown first, Hide Below of earlier ones can hide it")
	if index < _overview.sections.size() - 1: item.add_button(1, AdventureActionMenu.get_editor_icon("MoveDown"), Act.DOWN, false, "Later")
	if section.encounter == null: item.add_button(1, AdventureActionMenu.get_editor_icon("Add"), Act.ADD, false, "A new event here, or one made already")
	elif section.encounter.places.has(AdventureLayout.get_key(_overview.location)):
		item.add_button(1, AdventureActionMenu.get_editor_icon("Remove"), Act.REMOVE, false, "Not here any more (it stays)")
	if section.events.is_empty():
		_tree.create_item(item).set_text(0, "(none)")
	for event: AdventureEvent in section.events:
		var row: TreeItem = _tree.create_item(item)
		row.set_text(0, AdventureGraph.get_title(event) + (" (near)" if event.where == AdventureEvent.Where.NEAR and section.encounter != null else ""))
		var needs: String = AdventureEventOverview.get_condition_text(event.conditions)
		row.set_text(1, "when %s" % needs if not needs.is_empty() else "")
		row.set_metadata(0, event)
		if section.encounter == null and not AdventureEventEditing.is_inside_file(event):
			row.add_button(1, AdventureActionMenu.get_editor_icon("Remove"), Act.REMOVE, false, "Remove from here (the file stays)")

func _on_item_selected() -> void:
	var resource: Resource = _tree.get_selected().get_metadata(0) as Resource
	if resource != null: EditorInterface.edit_resource(resource)

func _on_item_activated() -> void:
	var event: AdventureEvent = _tree.get_selected().get_metadata(0) as AdventureEvent if _tree.get_selected() != null else null
	if event != null: event_opened.emit(event, get_location())

func _on_button_clicked(item: TreeItem, _column: int, id: int, _mouse_button: int) -> void:
	var location: AdventureLocation = get_location()
	var resource: Resource = item.get_metadata(0) as Resource
	match id:
		Act.UP, Act.DOWN:
			var order: Array[String] = _overview.get_order_moving(item.get_index(), -1 if id == Act.UP else 1)
			_request([[location, &"order", order]], "Reorder %s" % AdventureGraph.get_title(location))
		Act.ADD:
			_menu.show_actions({
				"New event here": event_requested.emit.bind(location, false),
				"New scenario here": event_requested.emit.bind(location, true),
				"Add event…": existing_event_requested.emit.bind(location, _menu.show_actions),
			})
		Act.REMOVE:
			if resource is AdventureEncounter:
				var title: String = AdventureGraph.get_title(resource as AdventureEncounter)
				_request(AdventureMapEditing.get_changes_placing(resource as AdventureEncounter, location, false), "%s not at %s any more" % [title, AdventureGraph.get_title(location)])
			else: _request(AdventureMapEditing.get_changes_removing(location, resource as AdventureEvent), "Remove %s from %s" % [AdventureGraph.get_title(resource as AdventureEvent), AdventureGraph.get_title(location)])

## New encounters here, and those made already that can't show here yet
func _get_encounter_actions() -> Dictionary[String, Callable]:
	var location: AdventureLocation = get_location()
	var actions: Dictionary[String, Callable] = {
		"New encounter here…": encounter_requested.emit.bind(location, false, null),
		"New monster encounter here…": encounter_requested.emit.bind(location, true, null),
	}
	var shown: Array[AdventureEncounter] = [ ]
	for section: AdventureLocationOverview.Section in _overview.sections: if section.encounter != null: shown.append(section.encounter)
	for encounter: AdventureEncounter in _encounters:
		if shown.has(encounter): continue
		var title: String = AdventureGraph.get_title(encounter)
		actions["Place %s here" % title] = _request.bind(AdventureMapEditing.get_changes_placing(encounter, location, true), "%s could be at %s" % [title, AdventureGraph.get_title(location)])
	return actions

func _request(changes: Array[Array], action: String) -> void:
	if not changes.is_empty(): changes_requested.emit(changes, action, null)
