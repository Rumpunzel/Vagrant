@tool
class_name AdventureLocationView
extends VBoxContainer

## The panel beside the map for the location selected there: a small banner with its background (or its area's), its texts to edit, and
## ([AdventureLocationOverview]) a section per source of events in its order (its own events, then the encounters that can show there), each
## with the events that could show and what they need; what can come here below. ▲ ▼ change the order, + adds events or encounters, ✕ takes
## them off here. Selecting a row shows it in the Inspector; double-click an event to open it.

signal event_opened(event: AdventureEvent, host: AdventurePage)
signal changes_requested(changes: Array[Array], action: String, file: Resource)
## A new event (or scenario) among [param location]'s own events
signal event_requested(location: AdventureLocation, scenario: bool)
## Pick an event made already for [param location]'s own events; [param show_actions] shows the choices
signal existing_event_requested(location: AdventureLocation, show_actions: Callable)
signal encounter_requested(location: AdventureLocation, monster: bool, profile: MonsterProfile)
## Play from [param page] ([param event]: none)
signal play_requested(page: AdventurePage, event: AdventureEvent)

enum Act { UP, DOWN, ADD, REMOVE }

const WIDTH: float = 400.0
const BANNER_HEIGHT: float = 110.0
const TEXT_HEIGHT: float = 70.0

var _overview: AdventureLocationOverview
var _encounters: Array[AdventureEncounter] = [ ]
var _title: Label
var _subtitle: Label
var _banner: TextureRect
var _text: TextEdit
var _first_text: TextEdit
var _tree: Tree
var _menu: AdventureActionMenu

func setup() -> void:
	custom_minimum_size.x = WIDTH
	add_child(_make_banner())
	_text = _make_text_box("Its text", &"description")
	_first_text = _make_text_box("The first visit (none: its text)", &"first_description")
	_tree = Tree.new()
	_tree.add_theme_stylebox_override(&"panel", StyleBoxEmpty.new())
	_tree.columns = 2
	_tree.hide_root = true
	_tree.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_tree.set_column_expand_ratio(0, 1)
	_tree.set_column_expand_ratio(1, 1)
	_tree.set_column_clip_content(1, true)
	_tree.item_activated.connect(_on_item_activated)
	_tree.item_selected.connect(_on_item_selected)
	_tree.button_clicked.connect(_on_button_clicked)
	add_child(_tree)
	_menu = AdventureActionMenu.new()
	add_child(_menu)

## The background, faded at the bottom under its title; the buttons at the top
func _make_banner() -> Control:
	var banner: Control = Control.new()
	banner.custom_minimum_size.y = BANNER_HEIGHT
	banner.clip_contents = true
	_banner = TextureRect.new()
	_banner.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_banner.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner.add_child(_banner)
	_banner.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var fade: TextureRect = TextureRect.new()
	var gradient: GradientTexture2D = GradientTexture2D.new()
	gradient.gradient = Gradient.new()
	gradient.gradient.set_color(0, Color(0, 0, 0, 0))
	gradient.gradient.set_color(1, Color(0, 0, 0, 0.85))
	gradient.gradient.set_offset(0, 0.2)
	gradient.fill_from = Vector2(0, 0)
	gradient.fill_to = Vector2(0, 1)
	fade.texture = gradient
	fade.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fade.stretch_mode = TextureRect.STRETCH_SCALE
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner.add_child(fade)
	fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var margin: MarginContainer = MarginContainer.new()
	for side: String in ["left", "top", "right", "bottom"]: margin.add_theme_constant_override("margin_" + side, 8)
	banner.add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var stack: VBoxContainer = VBoxContainer.new()
	stack.add_theme_constant_override(&"separation", 0)
	margin.add_child(stack)
	var buttons: HBoxContainer = HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_END
	buttons.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stack.add_child(buttons)
	buttons.add_child(_make_banner_button("PlayScene", "Play from here (chance decides what happens, as in the game)", _on_play))
	buttons.add_child(_make_banner_button("Add", "A new encounter here, or one made already", _on_add_encounter))
	buttons.add_child(_make_banner_button("Close", "Close (select a location on the map to show it again)", hide))
	_title = _make_banner_label(&"HeaderMedium")
	stack.add_child(_title)
	_subtitle = _make_banner_label(&"")
	stack.add_child(_subtitle)
	return banner

func _make_banner_button(icon_name: String, tooltip: String, on_pressed: Callable) -> Button:
	var button: Button = Button.new()
	button.icon = AdventureActionMenu.get_editor_icon(icon_name)
	button.tooltip_text = tooltip
	button.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	button.pressed.connect(on_pressed)
	return button

## Outlined, so it reads on any background
static func _make_banner_label(variation: StringName) -> Label:
	var label: Label = Label.new()
	label.theme_type_variation = variation
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.add_theme_constant_override(&"outline_size", 6)
	label.add_theme_color_override(&"font_outline_color", Color(0, 0, 0, 0.8))
	return label

## Changed once it loses focus (one undo step)
func _make_text_box(placeholder: String, property: StringName) -> TextEdit:
	var box: TextEdit = TextEdit.new()
	box.placeholder_text = placeholder
	box.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	box.scroll_fit_content_height = true
	box.custom_minimum_size.y = TEXT_HEIGHT
	box.focus_exited.connect(_on_text_edited.bind(box, property))
	add_child(box)
	return box

func _on_text_edited(box: TextEdit, property: StringName) -> void:
	var location: AdventureLocation = get_location()
	if location == null or box.text == location.get(property): return
	changes_requested.emit([[location, property, box.text]], "%s's %s" % [AdventureGraph.get_title(location), "text" if property == &"description" else "first-visit text"], location)

## Its own background, else its area's
func _show_header(location: AdventureLocation) -> void:
	var background: Texture2D = null
	var notes: Array[String] = [ ]
	if location != null:
		background = location.background if location.background != null else location.get_area_background()
		if location.area != null: notes.append(location.area.name)
		if location.background == null: notes.append("the area's background" if background != null else "no background")
	_banner.texture = background
	_subtitle.text = " · ".join(notes)
	_text.text = location.description if location != null else ""
	_first_text.text = location.first_description if location != null else ""

func _on_play() -> void:
	if get_location() != null: play_requested.emit(get_location(), null)

func _on_add_encounter() -> void:
	if get_location() != null: _menu.show_actions(_get_encounter_actions())

func get_location() -> AdventureLocation: return _overview.location if _overview != null else null

## Shows [param location] (none: hides); [param pages]: the map's pages, whose decisions may bring encounters here
func show_location(location: AdventureLocation, encounters: Array[AdventureEncounter], pages: Array[AdventurePage]) -> void:
	_tree.clear()
	_encounters = encounters
	_overview = AdventureLocationOverview.new(location, encounters, pages) if location != null else null
	visible = location != null
	if location == null: return
	_title.text = AdventureGraph.get_title(location)
	_show_header(location)
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
		item.set_tooltip_text(1, item.get_text(1))
		item.set_metadata(0, arrival.page if arrival.page is AdventureEvent else arrival.encounter)

func _add_section(root: TreeItem, index: int) -> void:
	var section: AdventureLocationOverview.Section = _overview.sections[index]
	var item: TreeItem = _tree.create_item(root)
	item.set_text(0, "%d · %s" % [index + 1, AdventureGraph.get_title(section.encounter) if section.encounter != null else "Its own events"])
	item.set_text(1, section.reason)
	item.set_icon(0, AdventureActionMenu.get_editor_icon("CharacterBody2D" if section.encounter != null else "Environment"))
	item.set_metadata(0, section.encounter if section.encounter != null else _overview.location)
	if index > 0: item.add_button(1, AdventureActionMenu.get_editor_icon("MoveUp"), Act.UP, false, "Earlier: shown first; an earlier \"only this\" event hides it")
	if index < _overview.sections.size() - 1: item.add_button(1, AdventureActionMenu.get_editor_icon("MoveDown"), Act.DOWN, false, "Later")
	if section.encounter == null: item.add_button(1, AdventureActionMenu.get_editor_icon("Add"), Act.ADD, false, "A new event here, or one made already")
	elif section.encounter.places.has(AdventureLayout.get_key(_overview.location)):
		item.add_button(1, AdventureActionMenu.get_editor_icon("Remove"), Act.REMOVE, false, "Not here any more (it stays)")
	if section.events.is_empty():
		_tree.create_item(item).set_text(0, "(none)")
	for event: AdventureEvent in section.events:
		var row: TreeItem = _tree.create_item(item)
		row.set_text(0, AdventureGraph.get_title(event) + (" (near)" if event.where == AdventureEvent.Where.NEAR and section.encounter != null else ""))
		var needs: String = AdventureEventGraph.describe_conditions(event.conditions)
		row.set_text(1, "when %s" % needs if not needs.is_empty() else "")
		row.set_tooltip_text(1, row.get_text(1))
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
