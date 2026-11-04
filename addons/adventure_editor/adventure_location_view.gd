@tool
class_name AdventureLocationView
extends VBoxContainer

## The panel beside the map for the location selected there: a small banner with its background (or its area's), its texts to edit, and
## ([AdventureLocationOverview]) a section per source of events in its order (its own events, then the encounters that can show there), each
## with the events that could show; what can come here below. When and how each shows is in its tooltip. ▲ ▼ change the order, + adds events
## or encounters, ✕ takes them off here; clicking an event or encounter opens it.

signal event_opened(event: AdventureEvent, host: AdventurePage)
signal changes_requested(changes: Array[Array], action: String, file: Resource)
## A new event (or scenario) among [param location]'s own events
signal event_requested(location: AdventureLocation, scenario: bool)
## Pick an event made already for [param location]'s own events; [param show_actions] shows the choices
signal existing_event_requested(location: AdventureLocation, show_actions: Callable)
signal encounter_requested(location: AdventureLocation, monster: bool, profile: MonsterProfile)
## Play from [param page] ([param event]: none)
signal play_requested(page: AdventurePage, event: AdventureEvent)

const WIDTH: float = 300.0
const BANNER_HEIGHT: float = 110.0
const TEXT_HEIGHT: float = 70.0
const INDENT: float = 16.0

## Rich tooltips for its rows; none: plain ones
var tooltips: AdventureTooltips

var _overview: AdventureLocationOverview
var _encounters: Array[AdventureEncounter] = [ ]
var _title: Label
var _subtitle: Label
var _banner: TextureRect
var _text: TextEdit
var _first_text: TextEdit
var _rows: VBoxContainer
var _menu: AdventureActionMenu

func setup() -> void:
	custom_minimum_size.x = WIDTH
	add_child(_make_banner())
	_text = _make_text_box("Its text", &"description")
	_first_text = _make_text_box("The first visit (none: its text)", &"first_description")
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	_rows = VBoxContainer.new()
	_rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_rows.add_theme_constant_override(&"separation", 0)
	scroll.add_child(_rows)
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
	for button: Button in [
		AdventureUi.text_button("", "PlayScene", "Play from here (chance decides what happens, as in the game)", _on_play),
		AdventureUi.text_button("", "Add", "A new encounter here, or one made already", _on_add_encounter),
		AdventureUi.text_button("", "Close", "Close (select a location on the map to show it again)", hide),
	]:
		button.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		buttons.add_child(button)
	_title = _make_banner_label(&"HeaderMedium")
	stack.add_child(_title)
	_subtitle = _make_banner_label(&"")
	stack.add_child(_subtitle)
	return banner

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
	var background: Texture2D = location.background if location.background != null else location.get_area_background()
	var notes: Array[String] = [ ]
	if location.area != null: notes.append(location.area.name)
	if location.background == null: notes.append("the area's background" if background != null else "no background")
	_banner.texture = background
	_title.text = AdventureGraph.get_title(location)
	_subtitle.text = " · ".join(notes)
	_text.text = location.description
	_first_text.text = location.first_description

func _on_play() -> void:
	if get_location() != null: play_requested.emit(get_location(), null)

func _on_add_encounter() -> void:
	if get_location() != null: _menu.show_actions(_get_encounter_actions())

func get_location() -> AdventureLocation: return _overview.location if _overview != null else null

## Shows [param location] (none: hides); [param pages]: the map's pages, whose decisions may bring encounters here
func show_location(location: AdventureLocation, encounters: Array[AdventureEncounter], pages: Array[AdventurePage]) -> void:
	for child: Node in _rows.get_children(): child.queue_free()
	_encounters = encounters
	_overview = AdventureLocationOverview.new(location, encounters, pages) if location != null else null
	visible = location != null
	if location == null: return
	_show_header(location)
	for index: int in _overview.sections.size(): _add_section(index)
	if _overview.arrivals.is_empty(): return
	_rows.add_child(_make_heading(AdventureActionMenu.get_editor_icon("MoveRight"), "Can come here", ""))
	for arrival: AdventureLocationOverview.Arrival in _overview.arrivals:
		var row: Button = _make_row(arrival.encounter, "%s, from %s" % [AdventureGraph.get_title(arrival.encounter), AdventureGraph.get_title(arrival.page)])
		if tooltips != null: tooltips.attach(row, arrival.decision, "open %s" % AdventureGraph.get_title(arrival.encounter))
		else: row.tooltip_text = "\"%s\" brings it here" % arrival.decision.description.get_slice("\n", 0)
		_rows.add_child(row)

## Its heading (number, whose, why it is here, ▲ ▼ + ✕), then a row per event that could show
func _add_section(index: int) -> void:
	var location: AdventureLocation = _overview.location
	var section: AdventureLocationOverview.Section = _overview.sections[index]
	var whose: String = AdventureGraph.get_title(section.encounter) if section.encounter != null else "Its own events"
	var icon: Texture2D = AdventureActionMenu.get_event_icon(section.encounter) if section.encounter != null else AdventureActionMenu.get_editor_icon("Environment")
	var heading: HBoxContainer = _make_heading(icon, "%d · %s" % [index + 1, whose], section.reason if section.encounter != null else "")
	if section.encounter != null:
		var open: Button = heading.get_child(1) as Button
		open.pressed.connect(event_opened.emit.bind(section.encounter, location))
		if tooltips != null: tooltips.attach(open, section.encounter, "open it")
	if index > 0: heading.add_child(AdventureUi.icon_button("MoveUp", "▲", "Earlier: shown first; an earlier \"only its own\" event hides it", _move.bind(index, -1)))
	if index < _overview.sections.size() - 1: heading.add_child(AdventureUi.icon_button("MoveDown", "▼", "Later", _move.bind(index, 1)))
	if section.encounter == null:
		var additions: Dictionary[String, Callable] = {
			"New event here": event_requested.emit.bind(location, false),
			"New scenario here": event_requested.emit.bind(location, true),
			"Add event…": existing_event_requested.emit.bind(location, _menu.show_actions),
		}
		heading.add_child(AdventureUi.icon_button("Add", "+", "A new event here, or one made already", _menu.show_actions.bind(additions)))
	elif section.encounter.places.has(AdventureLayout.get_key(location)):
		var changes: Array[Array] = AdventureMapEditing.get_changes_placing(section.encounter, location, false)
		var action: String = "%s not at %s any more" % [AdventureGraph.get_title(section.encounter), AdventureGraph.get_title(location)]
		heading.add_child(AdventureUi.icon_button("Remove", "✕", "Not here any more (it stays)", _request.bind(changes, action)))
	_rows.add_child(heading)
	if section.events.is_empty():
		var none: Label = AdventureUi.info("none")
		none.custom_minimum_size.x = 0
		var indented: HBoxContainer = HBoxContainer.new()
		indented.add_child(AdventureUi.spacer(INDENT))
		indented.add_child(none)
		_rows.add_child(indented)
	for event: AdventureEvent in section.events: _rows.add_child(_make_event_row(event, section.encounter != null))

## Clicking opens it; its own events (not stored in the location's file) can be taken off here
func _make_event_row(event: AdventureEvent, of_encounter: bool) -> HBoxContainer:
	var row: HBoxContainer = HBoxContainer.new()
	row.add_child(AdventureUi.spacer(INDENT))
	var text: String = AdventureGraph.get_title(event) + (" (near)" if of_encounter and event.where == AdventureEvent.Where.NEAR else "")
	if AdventureGraph.happens_by_chance(event): text += " 🎲"
	var open: Button = _make_row(event, text)
	if tooltips != null: tooltips.attach(open, event, "open it")
	else:
		var needs: String = AdventureEventGraph.describe_conditions(event.conditions)
		open.tooltip_text = "when %s" % needs if not needs.is_empty() else "always"
	row.add_child(open)
	if not of_encounter and not AdventureEventEditing.is_inside_file(event):
		var location: AdventureLocation = _overview.location
		var action: String = "Remove %s from %s" % [AdventureGraph.get_title(event), AdventureGraph.get_title(location)]
		row.add_child(AdventureUi.icon_button("Remove", "✕", "Remove from here (the file stays)", _request.bind(AdventureMapEditing.get_changes_removing(location, event), action)))
	return row

## A flat button with [param about]'s icon opening it
func _make_row(about: AdventureEvent, text: String) -> Button:
	var open: Button = Button.new()
	open.flat = true
	open.text = text
	open.icon = AdventureActionMenu.get_event_icon(about)
	open.add_theme_constant_override(&"icon_max_width", AdventureActionMenu.ICON_SIZE)
	open.alignment = HORIZONTAL_ALIGNMENT_LEFT
	open.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	open.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	open.pressed.connect(event_opened.emit.bind(about, get_location()))
	return open

## [param icon] and [param text] (a button, so an encounter's can open it), [param reason] faded after it
func _make_heading(icon: Texture2D, text: String, reason: String) -> HBoxContainer:
	var heading: HBoxContainer = HBoxContainer.new()
	var mark: TextureRect = TextureRect.new()
	mark.texture = icon
	mark.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	mark.custom_minimum_size = Vector2.ONE * AdventureActionMenu.ICON_SIZE
	heading.add_child(mark)
	var title: Button = Button.new()
	title.flat = true
	title.text = text
	title.alignment = HORIZONTAL_ALIGNMENT_LEFT
	title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if Engine.is_editor_hint(): title.add_theme_font_override(&"font", get_theme_font(&"bold", &"EditorFonts"))
	heading.add_child(title)
	if not reason.is_empty(): heading.add_child(AdventureUi.info(reason))
	return heading

func _move(index: int, step: int) -> void:
	var location: AdventureLocation = get_location()
	_request([[location, &"order", _overview.get_order_moving(index, step)]], "Reorder %s" % AdventureGraph.get_title(location))

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
