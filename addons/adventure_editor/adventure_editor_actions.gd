@tool
class_name AdventureEditorActions
extends Node

## What the adventure editor makes and deletes through dialogs: new locations, events, scenario options and encounters, events made already
## to list somewhere, and deleting. It owns the dialogs and works on [member editor]'s adventure, edits and layout.

var editor: AdventureEditor
var _new_location_dialog: AdventureNewLocationDialog
var _texts_dialog: AdventureTextsDialog
var _file_dialog: EditorFileDialog
var _delete_dialog: ConfirmationDialog
var _profile_dialog: EditorFileDialog

func setup(of: AdventureEditor) -> void:
	editor = of
	_make_dialogs()

## Asks for a name, then calls [param then] with it
func ask_name(title: String, label: String, then: Callable) -> void:
	_texts_dialog.ask(title, [AdventureTextsDialog.Field.new(label, "")] as Array[AdventureTextsDialog.Field], _on_named.bind(then))

## A name left empty asks for nothing
func _on_named(texts: Array[String], then: Callable) -> void:
	if not texts[0].is_empty(): then.call(texts[0])

## A new event as the last option of [param scenario]
func ask_for_option(scenario: AdventureEventScenario) -> void:
	ask_name("New option", "Title", _create_event.bind(scenario, false))

func _make_dialogs() -> void:
	_new_location_dialog = AdventureNewLocationDialog.new()
	_new_location_dialog.location_confirmed.connect(_create_location)
	add_child(_new_location_dialog)
	_texts_dialog = AdventureTextsDialog.new()
	add_child(_texts_dialog)
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

## Events made already (and any other file) as the last option of [param scenario]
func offer_options(scenario: AdventureEventScenario, show_actions: Callable) -> void:
	var taken: Array = scenario.events.duplicate()
	taken.append(scenario)
	_offer(taken, _add_option.bind(scenario), show_actions)

func _add_option(event: AdventureEvent, scenario: AdventureEventScenario) -> void:
	var options: Array[AdventureEvent] = scenario.events.duplicate()
	options.append(event)
	editor.get_edits().apply(AdventureEventEditing.get_changes_listing(scenario, options), "Add %s to %s" % [AdventureGraph.get_title(event), AdventureGraph.get_title(scenario)])

func ask_for_location(at: Vector2) -> void:
	if editor.adventure != null: _new_location_dialog.open(editor.get_graph().areas, at)

## Creates the location's file (and a new area's) right away; Ctrl+Z doesn't delete files
## Its file (and a new area's) is part of the undo step
func _create_location(title: String, area: AdventureArea, new_area_name: String, at: Vector2) -> void:
	var files: Dictionary[String, Resource] = {}
	if area == null:
		area = AdventureMakers.make_area(new_area_name)
		area.resource_path = AdventureMakers.get_area_path(editor.adventure, new_area_name)
		files[area.resource_path] = area
	var page: AdventurePage = AdventureMakers.make_location(title, area)
	var path: String = AdventureMakers.get_location_path(area, title)
	files[path] = page
	var changes: Array[Array] = [ ]
	if not editor.get_edits().create(files, changes, "New location %s" % title): return
	editor.get_layout().positions[AdventureLayout.get_key(page)] = at
	editor.save_layout()
	editor.rebuild()

func ask_for_event(location: AdventureLocation, scenario: bool) -> void:
	ask_name("New scenario" if scenario else "New event", "Title", _create_event.bind(location, scenario))

## The adventure's events (those met and every file in an events folder) not on [param location] yet, and any other file;
## [param show_actions] shows the menu
func offer_events(location: AdventureLocation, show_actions: Callable) -> void:
	_offer(location.get_own_events(), func(event: AdventureEvent) -> void: editor.get_map().put_event(location, event), show_actions)

## A menu of the adventure's events (those met and every file in an events folder) but [param taken], and any other file; [param on_pick] gets the event
func _offer(taken: Array, on_pick: Callable, show_actions: Callable) -> void:
	var events: Array[AdventureEvent] = editor.get_all_events()
	var actions: Dictionary[String, Callable] = {}
	for event: AdventureEvent in events:
		if not taken.has(event): actions[AdventureEditor.describe_event(event)] = on_pick.bind(event)
	actions["Other file…"] = func() -> void:
		for connection: Dictionary in _file_dialog.file_selected.get_connections(): _file_dialog.file_selected.disconnect(connection["callable"])
		_file_dialog.file_selected.connect(func(path: String) -> void:
			var event: AdventureEvent = load(path) as AdventureEvent
			if event != null: on_pick.call(event)
			else: push_warning("%s is no event" % path)
		)
		_file_dialog.popup_file_dialog()
	show_actions.call(actions)

## Creates the event's file and lists it on [param host] (a location, or a scenario as its last option), as one undo step
func _create_event(title: String, host: AdventurePage, scenario: bool) -> void:
	var event: AdventureEvent = AdventureMakers.make_event(title, scenario)
	var files: Dictionary[String, Resource] = {AdventureMakers.get_event_path(host, title): event}
	var events: Array[AdventureEvent] = AdventureGraph.get_listed_on(host)
	events.append(event)
	editor.get_edits().create(files, AdventureEventEditing.get_changes_listing(host, events), "New %s on %s" % [title, AdventureGraph.get_title(host)])

## An NPC is named in a dialog; a monster is named after its profile (asked for if not given)
func ask_for_encounter(location: AdventureLocation, monster: bool, profile: MonsterProfile) -> void:
	if not monster:
		ask_name("New encounter", "Name", func(title: String) -> void: _create_encounter(title, location, null))
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
	var files: Dictionary[String, Resource] = AdventureMakers.make_encounter_files(editor.adventure, title, location, profile)
	var encounters: Array[AdventureEncounter] = editor.adventure.encounters.duplicate()
	encounters.append(files.values().back() as AdventureEncounter)
	editor.get_edits().create(files, [[editor.adventure, &"encounters", encounters, editor.adventure]] as Array[Array], "New encounter %s" % title)

## Asks first; the starting page can't go
func ask_to_delete(resource: Resource) -> void:
	if resource == editor.adventure.starting_page:
		push_warning("The starting page can't be deleted; set another one on the adventure first")
		return
	var title: String = AdventureGraph.get_title(resource as AdventurePage) if resource is AdventurePage else (resource as AdventureArea).name
	_delete_dialog.dialog_text = "Delete %s?\nWhat points to it is removed (Ctrl+Z brings that back); its file goes to the system trash." % title
	for connection: Dictionary in _delete_dialog.confirmed.get_connections(): _delete_dialog.confirmed.disconnect(connection["callable"])
	_delete_dialog.confirmed.connect(_delete.bind(resource, title))
	_delete_dialog.popup_centered()

func _delete(resource: Resource, title: String) -> void:
	var changes: Array[Array] = [ ]
	if resource is AdventureArea: changes = AdventureEventEditing.get_changes_forgetting_area(resource as AdventureArea, editor.get_graph().pages)
	else:
		var roots: Array[AdventurePage] = editor.get_graph().pages.duplicate()
		for event: AdventureEvent in editor.get_all_events(): if not roots.has(event): roots.append(event)
		changes = AdventureEventEditing.get_changes_forgetting(resource as AdventurePage, roots)
	var key: String = AdventureLayout.get_key(resource)
	if editor.adventure.encounters.has(resource):
		var encounters: Array[AdventureEncounter] = editor.adventure.encounters.duplicate()
		encounters.erase(resource)
		changes.append([editor.adventure, &"encounters", encounters, editor.adventure])
	editor.get_edits().delete(resource, changes, "Delete %s" % title)
	editor.get_layout().positions.erase(key)
	editor.save_layout()
