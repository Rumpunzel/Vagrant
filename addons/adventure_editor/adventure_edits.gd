@tool
class_name AdventureEdits
extends RefCounted

## Edits to an adventure's resources: each a step of the undo history, the files they change unsaved until [method save]; new files and deleted ones
## are part of their step (undoing a new file moves it to the system trash, redo saves it again; a deleted file stays in the trash, undo restores only
## what pointed at it). Works with the editor's undo history, or with a plain [UndoRedo] in tests.

## A step was done or undone
signal changed

## Moves a file away: to the system trash; tests swap it
var trash: Callable = func(path: String) -> void: OS.move_to_trash(ProjectSettings.globalize_path(path))

## Files changed by edits and not saved yet
var _unsaved: Array[Resource] = [ ]
var _editor_history: EditorUndoRedoManager
var _history: UndoRedo

## [param undo_redo]: an [EditorUndoRedoManager] or an [UndoRedo]
func _init(undo_redo: Object) -> void:
	_editor_history = undo_redo as EditorUndoRedoManager
	_history = undo_redo as UndoRedo
	assert(_editor_history != null or _history != null, "Edits need an undo history")

## Changes as one undo step called [param action]: [resource, property, value] or [resource, property, value, the file it is stored in];
## [param file]: the file for those without one (none: each resource is a file of its own)
func apply(changes: Array[Array], action: String, file: Resource = null) -> void:
	if changes.is_empty(): return
	_create_action(action, file if file != null else changes[0][0])
	_add_changes(changes, file)
	_commit()

## Saves [param files] (path -> resource) as new files and applies [param changes], as one undo step; refused if a file is there already
func create(files: Dictionary[String, Resource], changes: Array[Array], action: String, file: Resource = null) -> bool:
	for path: String in files:
		if FileAccess.file_exists(path):
			push_error("%s exists already" % path)
			return false
	_create_action(action, files.values()[0])
	for path: String in files:
		_add_call(true, &"_save_new", [files[path], path])
		_add_call(false, &"_move_away", [path])
	_add_changes(changes, file)
	_commit()
	return true

## Applies [param changes] (what pointed at [param resource]) and moves its file to the trash, as one undo step; undoing it restores the changes only
func delete(resource: Resource, changes: Array[Array], action: String) -> void:
	_create_action(action, resource)
	_add_changes(changes, null)
	_add_call(true, &"_move_away", [resource.resource_path])
	_commit()

func has_unsaved_changes() -> bool: return not _unsaved.is_empty()

func is_unsaved(file: Resource) -> bool: return _unsaved.has(file)

func save() -> void:
	for file: Resource in _unsaved: if FileAccess.file_exists(file.resource_path): ResourceSaver.save(file)
	_unsaved.clear()

func _add_changes(changes: Array[Array], file: Resource) -> void:
	for change: Array in changes:
		var resource: Resource = change[0]
		var stored_in: Resource = change[3] if change.size() > 3 else file if file != null else resource
		_add_property(true, resource, change[1], change[2])
		_add_property(false, resource, change[1], resource.get(change[1]))
		_add_call(true, &"_changed", [stored_in])
		_add_call(false, &"_changed", [stored_in])

# The two histories differ in how actions and method calls are added
func _create_action(action: String, context: Object) -> void:
	if _editor_history != null: _editor_history.create_action(action, UndoRedo.MERGE_DISABLE, context)
	else: _history.create_action(action)

func _add_property(doing: bool, resource: Resource, property: StringName, value: Variant) -> void:
	if _editor_history != null:
		if doing: _editor_history.add_do_property(resource, property, value)
		else: _editor_history.add_undo_property(resource, property, value)
	elif doing: _history.add_do_property(resource, property, value)
	else: _history.add_undo_property(resource, property, value)

func _add_call(doing: bool, method: StringName, arguments: Array) -> void:
	if _editor_history != null:
		var adding: Callable = _editor_history.add_do_method if doing else _editor_history.add_undo_method
		adding.callv([self, method] + arguments)
	else:
		var call: Callable = Callable(self, method).bindv(arguments)
		if doing: _history.add_do_method(call)
		else: _history.add_undo_method(call)

func _commit() -> void:
	if _editor_history != null: _editor_history.commit_action()
	else: _history.commit_action()

func _save_new(resource: Resource, path: String) -> void:
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	resource.take_over_path(path)
	ResourceSaver.save(resource)
	_update_file_system(path)
	changed.emit()

func _move_away(path: String) -> void:
	if FileAccess.file_exists(path): trash.call(path)
	_update_file_system(path)
	changed.emit()

func _update_file_system(path: String) -> void:
	if Engine.is_editor_hint(): EditorInterface.get_resource_filesystem().update_file(path)

func _changed(file: Resource) -> void:
	if not _unsaved.has(file): _unsaved.append(file)
	changed.emit()
