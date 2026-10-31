@tool
class_name AdventureScenarioView
extends VBoxContainer

## A scenario or encounter as the list it is: whether it shows the first option that fits or all of them, when (its own conditions), and its
## options in order with what each needs (▲ ▼ reorder, ✕ takes one out, its file stays). An encounter also says where it could be.
## Selecting a row shows it in the Inspector; double-click an option to open it.

signal event_opened(event: AdventureEvent, host: AdventurePage)
signal changes_requested(changes: Array[Array], action: String, file: Resource)
## A new event as the last option of [param scenario]
signal option_requested(scenario: AdventureEventScenario)
## Pick an event made already as the last option; [param show_actions] shows the choices
signal existing_option_requested(scenario: AdventureEventScenario, show_actions: Callable)

enum Act { UP, DOWN, REMOVE }

var _scenario: AdventureEventScenario
var _host: AdventurePage
var _title: Label
var _pick: OptionButton
var _info: Label
var _tree: Tree
var _menu: AdventureActionMenu

func setup() -> void:
	var bar: HBoxContainer = HBoxContainer.new()
	add_child(bar)
	_title = Label.new()
	_title.theme_type_variation = &"HeaderMedium"
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.add_child(_title)
	_pick = OptionButton.new()
	_pick.add_item("Shows the first option that fits", AdventureEventScenario.Pick.FIRST)
	_pick.add_item("Shows every option that fits", AdventureEventScenario.Pick.ALL)
	_pick.item_selected.connect(_on_pick_selected)
	bar.add_child(_pick)
	bar.add_child(_make_button("Option", "A new event as the last option", func() -> void: option_requested.emit(_scenario)))
	bar.add_child(_make_button("Add event…", "An event made already as the last option", func() -> void: existing_option_requested.emit(_scenario, _menu.show_actions)))
	_info = Label.new()
	_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_info.modulate = Color(1, 1, 1, 0.8)
	add_child(_info)
	_tree = Tree.new()
	_tree.columns = 2
	_tree.hide_root = true
	_tree.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_tree.set_column_expand_ratio(0, 1)
	_tree.set_column_expand_ratio(1, 2)
	_tree.item_selected.connect(_on_item_selected)
	_tree.item_activated.connect(_on_item_activated)
	_tree.button_clicked.connect(_on_button_clicked)
	add_child(_tree)
	_menu = AdventureActionMenu.new()
	add_child(_menu)

## [param host]: where it is looked at from (the "At:" picker), passed on when an option is opened
func show_scenario(scenario: AdventureEventScenario, host: AdventurePage) -> void:
	_scenario = scenario
	_host = host
	_tree.clear()
	if scenario == null: return
	var encounter: AdventureEncounter = scenario as AdventureEncounter
	_title.text = AdventureGraph.get_title(scenario) + (" (encounter)" if encounter != null else " (scenario)")
	_pick.select(_pick.get_item_index(scenario.pick))
	var lines: Array[String] = [ ]
	var conditions: String = AdventureEventOverview.get_condition_text(scenario.conditions)
	if not conditions.is_empty(): lines.append("When %s" % conditions)
	if encounter != null:
		var places: Array[String] = [ ]
		for location: AdventureLocation in encounter.get_places(): places.append(AdventureGraph.get_title(location))
		lines.append("Could be at %s" % (", ".join(places) if not places.is_empty() else "no place yet (only events shown anywhere or near it)"))
	_info.text = "\n".join(lines)
	_info.visible = not lines.is_empty()
	var root: TreeItem = _tree.create_item()
	for index: int in scenario.events.size(): _add_option(root, index)
	if scenario.events.is_empty(): _tree.create_item(root).set_text(0, "(no options yet)")

func _add_option(root: TreeItem, index: int) -> void:
	var option: AdventureEvent = _scenario.events[index]
	var item: TreeItem = _tree.create_item(root)
	item.set_metadata(0, option)
	if option == null:
		item.set_text(0, "%d · (empty)" % (index + 1))
		return
	var kind: String = " (scenario)" if option is AdventureEventScenario else " (near)" if option.where == AdventureEvent.Where.NEAR else " (anywhere)" if option.where == AdventureEvent.Where.ANYWHERE else ""
	item.set_text(0, "%d · %s%s" % [index + 1, AdventureGraph.get_title(option), kind])
	var needs: String = AdventureEventOverview.get_condition_text(option.conditions)
	item.set_text(1, "when %s" % needs if not needs.is_empty() else "always fits")
	if index > 0: item.add_button(1, AdventureActionMenu.get_editor_icon("MoveUp"), Act.UP, false, "Earlier: checked first")
	if index < _scenario.events.size() - 1: item.add_button(1, AdventureActionMenu.get_editor_icon("MoveDown"), Act.DOWN, false, "Later")
	item.add_button(1, AdventureActionMenu.get_editor_icon("Remove"), Act.REMOVE, AdventureEventEditing.is_inside_file(option), "Not an option any more (its file stays)")

func _on_pick_selected(index: int) -> void:
	var pick: int = _pick.get_item_id(index)
	if pick == _scenario.pick: return
	changes_requested.emit([[_scenario, &"pick", pick, AdventureEventEditing.get_file(_scenario)]] as Array[Array], "%s: %s" % [AdventureGraph.get_title(_scenario), _pick.get_item_text(index)], null)

func _on_item_selected() -> void:
	var resource: Resource = _tree.get_selected().get_metadata(0) as Resource
	if resource != null: EditorInterface.edit_resource(resource)

func _on_item_activated() -> void:
	var option: AdventureEvent = _tree.get_selected().get_metadata(0) as AdventureEvent
	if option != null: event_opened.emit(option, _host)

func _on_button_clicked(item: TreeItem, _column: int, id: int, _mouse_button: int) -> void:
	var options: Array[AdventureEvent] = _scenario.events.duplicate()
	var index: int = item.get_index()
	var option: AdventureEvent = options.pop_at(index)
	var title: String = AdventureGraph.get_title(option) if option != null else "empty option"
	if id == Act.REMOVE:
		changes_requested.emit(AdventureEventEditing.get_changes_listing(_scenario, options), "Remove %s from %s" % [title, AdventureGraph.get_title(_scenario)], null)
		return
	options.insert(index + (-1 if id == Act.UP else 1), option)
	changes_requested.emit(AdventureEventEditing.get_changes_listing(_scenario, options), "Move %s" % title, null)

static func _make_button(text: String, tooltip: String, on_pressed: Callable) -> Button:
	var button: Button = Button.new()
	button.text = text
	button.tooltip_text = tooltip
	button.icon = AdventureActionMenu.get_editor_icon("Add")
	button.pressed.connect(on_pressed)
	return button
