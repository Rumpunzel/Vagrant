@tool
class_name AdventureEdits
extends RefCounted

## Edits to an adventure's resources: each a step of the undo history, the files they change unsaved until [method save]; and new files.
## Works with the editor's undo history, or with a plain [UndoRedo] in tests.

## A step was done or undone
signal changed

## Files changed by edits and not saved yet
var _unsaved: Array[Resource] = [ ]
var _create_action: Callable
var _add_do_property: Callable
var _add_undo_property: Callable
## Adds marking a file changed to the open action, both ways
var _add_changed_calls: Callable
var _commit_action: Callable

## [param undo_redo]: an [EditorUndoRedoManager] or an [UndoRedo]
func _init(undo_redo: Object) -> void:
	var editor_history: EditorUndoRedoManager = undo_redo as EditorUndoRedoManager
	var history: UndoRedo = undo_redo as UndoRedo
	assert(editor_history != null or history != null, "Edits need an undo history")
	# Actions and method calls differ between the two; properties and committing don't
	if editor_history != null:
		_create_action = func(action: String, context: Object) -> void: editor_history.create_action(action, UndoRedo.MERGE_DISABLE, context)
		_add_changed_calls = func(file: Resource) -> void:
			editor_history.add_do_method(self, &"_changed", file)
			editor_history.add_undo_method(self, &"_changed", file)
	else:
		_create_action = func(action: String, _context: Object) -> void: history.create_action(action)
		_add_changed_calls = func(file: Resource) -> void:
			history.add_do_method(_changed.bind(file))
			history.add_undo_method(_changed.bind(file))
	_add_do_property = Callable(undo_redo, &"add_do_property")
	_add_undo_property = Callable(undo_redo, &"add_undo_property")
	_commit_action = Callable(undo_redo, &"commit_action")

## [resource, property, value] changes as one undo step called [param action]. [param file]: the file they are stored in (none: each resource is a file of its own)
func apply(changes: Array[Array], action: String, file: Resource = null) -> void:
	if changes.is_empty(): return
	_create_action.call(action, file if file != null else changes[0][0])
	for change: Array in changes:
		var resource: Resource = change[0]
		var stored_in: Resource = file if file != null else resource
		_add_do_property.call(resource, change[1], change[2])
		_add_undo_property.call(resource, change[1], resource.get(change[1]))
		_add_changed_calls.call(stored_in)
	_commit_action.call()

func has_unsaved_changes() -> bool: return not _unsaved.is_empty()

func is_unsaved(file: Resource) -> bool: return _unsaved.has(file)

func save() -> void:
	for file: Resource in _unsaved: ResourceSaver.save(file)
	_unsaved.clear()

## Saves [param resource] as a new file at once (not undone); refused if one is there
func create_file(resource: Resource, path: String) -> bool:
	if FileAccess.file_exists(path):
		push_error("%s exists already" % path)
		return false
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	resource.take_over_path(path)
	if ResourceSaver.save(resource) != OK: return false
	if Engine.is_editor_hint(): EditorInterface.get_resource_filesystem().update_file(path)
	return true

func _changed(file: Resource) -> void:
	if not _unsaved.has(file): _unsaved.append(file)
	changed.emit()
