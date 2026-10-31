@tool
class_name AdventureStorylineView
extends VBoxContainer

## An encounter's storyline as a table ([AdventureStoryline]): a column per stage, a row per event (tick: it needs the stage) with a row per
## decision outcome below it (tick: it sets the stage). Selecting a row shows it in the Inspector; double-click an event to see its pages.

signal event_opened(event: AdventureEvent, host: AdventurePage)
signal changes_requested(changes: Array[Array], action: String, file: Resource)
## New files and changes as one undo step
signal files_requested(files: Dictionary[String, Resource], changes: Array[Array], action: String)
## Ask for a name, then call [param then] with it
signal text_requested(title: String, label: String, then: Callable)

const OUTCOME_COLOR: Color = Color(1, 1, 1, 0.75)
const UNKNOWN_COLOR: Color = Color(1, 0.55, 0.5)

var _storyline: AdventureStoryline
var _tree: Tree
var _menu: AdventureActionMenu

func setup() -> void:
	var bar: HBoxContainer = HBoxContainer.new()
	add_child(bar)
	bar.add_child(_make_button("Track", "A new stage track", _ask_for_track))
	bar.add_child(_make_button("Stage", "A new stage on a track", _offer_tracks))
	bar.add_child(_make_button("Event", "A new event needing a stage", _offer_stages))
	_tree = Tree.new()
	_tree.hide_root = true
	_tree.column_titles_visible = true
	_tree.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_tree.item_edited.connect(_on_item_edited)
	_tree.item_selected.connect(_on_item_selected)
	_tree.item_activated.connect(_on_item_activated)
	add_child(_tree)
	_menu = AdventureActionMenu.new()
	add_child(_menu)

func show_storyline(encounter: AdventureEncounter) -> void:
	_tree.clear()
	_storyline = AdventureStoryline.new(encounter) if encounter != null else null
	if _storyline == null: return
	_tree.columns = 1 + _storyline.columns.size()
	_tree.set_column_title(0, AdventureGraph.get_title(encounter))
	_tree.set_column_expand_ratio(0, 3)
	for index: int in _storyline.columns.size():
		_tree.set_column_title(index + 1, "%s\n%s" % [(_storyline.columns[index][0] as AdventureStageTrack).name, _storyline.columns[index][1]])
		_tree.set_column_expand_ratio(index + 1, 1)
	var root: TreeItem = _tree.create_item()
	var event_item: TreeItem = null
	for index: int in _storyline.rows.size():
		var row: AdventureStoryline.Row = _storyline.rows[index]
		var item: TreeItem = _tree.create_item(root if row.decision == null else event_item)
		if row.decision == null: event_item = item
		item.set_metadata(0, index)
		item.set_text(0, _describe(row))
		var unknown: Array[String] = _storyline.get_unknown_stages(row)
		if not unknown.is_empty():
			item.set_custom_color(0, UNKNOWN_COLOR)
			item.set_tooltip_text(0, "Not a stage of its track: %s" % ", ".join(unknown))
		elif row.decision != null: item.set_custom_color(0, OUTCOME_COLOR)
		for column: int in _storyline.columns.size():
			item.set_cell_mode(column + 1, TreeItem.CELL_MODE_CHECK)
			item.set_editable(column + 1, true)
			item.set_checked(column + 1, _storyline.is_ticked(row, _storyline.columns[column][0], _storyline.columns[column][1]))
			item.set_tooltip_text(column + 1, "Needs this stage" if row.decision == null else "Sets this stage")

## The event's title; an outcome: its decision (and outcome) on its page
static func _describe(row: AdventureStoryline.Row) -> String:
	if row.decision == null: return AdventureGraph.get_title(row.event) + (" (near)" if row.event.where == AdventureEvent.Where.NEAR else "")
	var text: String = row.decision.description.get_slice("\n", 0)
	if not row.outcome.name.is_empty(): text += " · " + row.outcome.name
	return text if row.page == row.event else "%s: %s" % [AdventureGraph.get_title(row.page), text]

func _on_item_edited() -> void:
	var item: TreeItem = _tree.get_edited()
	var column: int = _tree.get_edited_column()
	if item == null or column < 1: return
	var row: AdventureStoryline.Row = _storyline.rows[item.get_metadata(0)]
	var track: AdventureStageTrack = _storyline.columns[column - 1][0]
	var stage: String = _storyline.columns[column - 1][1]
	var on: bool = item.is_checked(column)
	var changes: Array[Array] = _storyline.get_changes_ticking(row, track, stage, on)
	var what: String = "Needs" if row.decision == null else "Sets"
	if not changes.is_empty(): changes_requested.emit(changes, "%s %s: %s %s" % [what, track.name, stage, "" if on else "(off)"], null)

func _on_item_selected() -> void:
	var row: AdventureStoryline.Row = _storyline.rows[_tree.get_selected().get_metadata(0)]
	EditorInterface.edit_resource(row.event if row.decision == null else row.decision)

func _on_item_activated() -> void:
	var row: AdventureStoryline.Row = _storyline.rows[_tree.get_selected().get_metadata(0)]
	event_opened.emit(row.event, null)

func _ask_for_track() -> void:
	if _storyline == null: return
	text_requested.emit("New track", "Name", func(track_name: String) -> void: _request(_storyline.get_changes_adding_track(track_name), "New track %s" % track_name))

func _offer_tracks() -> void:
	if _storyline == null: return
	var actions: Dictionary[String, Callable] = {}
	for track: AdventureStageTrack in _storyline.encounter.tracks:
		if track == null: continue
		actions["New stage on %s…" % track.name] = text_requested.emit.bind("New stage on %s" % track.name, "Name", _add_stage.bind(track))
	if actions.is_empty(): push_warning("Make a track first")
	else: _menu.show_actions(actions)

func _add_stage(stage: String, track: AdventureStageTrack) -> void:
	_request(_storyline.get_changes_adding_stage(track, stage), "New stage %s: %s" % [track.name, stage])

func _offer_stages() -> void:
	if _storyline == null: return
	var actions: Dictionary[String, Callable] = {}
	for column: Array in _storyline.columns:
		var label: String = "New event needing %s: %s…" % [(column[0] as AdventureStageTrack).name, column[1]]
		actions[label] = text_requested.emit.bind("New event", "Title", _add_event.bind(column[0], column[1]))
	if actions.is_empty(): push_warning("Make a track with stages first")
	else: _menu.show_actions(actions)

func _add_event(title: String, track: AdventureStageTrack, stage: String) -> void:
	var files: Dictionary[String, Resource] = _storyline.make_event_files(title, track, stage)
	files_requested.emit(files, _storyline.get_changes_listing(files.values()[0] as AdventureEvent), "New event %s" % title)

func _request(changes: Array[Array], action: String) -> void:
	if not changes.is_empty(): changes_requested.emit(changes, action, null)

static func _make_button(text: String, tooltip: String, on_pressed: Callable) -> Button:
	var button: Button = Button.new()
	button.text = text
	button.tooltip_text = tooltip
	button.icon = AdventureActionMenu.get_editor_icon("Add")
	button.pressed.connect(on_pressed)
	return button
