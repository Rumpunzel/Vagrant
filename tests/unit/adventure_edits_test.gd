extends GdUnitTestSuite

## The adventure editor's edits: undo steps, what is unsaved, new files; with a plain UndoRedo instead of the editor's history.

const NEW_FILE: String = "user://adventure_edits_test/new_page.tres"

var _history: UndoRedo
var _edits: AdventureEdits
var _changes: int

func before_test() -> void:
	_history = auto_free(UndoRedo.new())
	_edits = AdventureEdits.new(_history)
	_changes = 0
	_edits.changed.connect(func() -> void: _changes += 1)

func after_test() -> void:
	if FileAccess.file_exists(NEW_FILE): DirAccess.remove_absolute(NEW_FILE)

func test_applies_changes_as_one_undo_step() -> void:
	var page: AdventurePage = _page("Before")
	var other: AdventurePage = _page("Other before")
	var changes: Array[Array] = [[page, &"title", "After"], [other, &"title", "Other after"]]
	_edits.apply(changes, "Rename both")
	assert_str(page.title).is_equal("After")
	assert_str(other.title).is_equal("Other after")
	assert_str(_history.get_current_action_name()).is_equal("Rename both")
	_history.undo()
	assert_str(page.title).is_equal("Before")
	assert_str(other.title).is_equal("Other before")
	_history.redo()
	assert_str(page.title).is_equal("After")

func test_marks_the_file_changes_are_stored_in() -> void:
	var file: AdventurePage = _page("File")
	var inside: AdventurePage = _page("Inside")
	var changes: Array[Array] = [[inside, &"title", "Changed"]]
	_edits.apply(changes, "Rename", file)
	assert_bool(_edits.is_unsaved(file)).is_true()
	assert_bool(_edits.is_unsaved(inside)).is_false()
	assert_bool(_edits.has_unsaved_changes()).is_true()
	# Undoing changes the file again
	_history.undo()
	assert_int(_changes).is_equal(2)

func test_without_a_file_each_resource_is_its_own() -> void:
	var page: AdventurePage = _page("Page")
	var changes: Array[Array] = [[page, &"title", "Changed"]]
	_edits.apply(changes, "Rename")
	assert_bool(_edits.is_unsaved(page)).is_true()

func test_nothing_to_apply() -> void:
	var changes: Array[Array] = [ ]
	_edits.apply(changes, "Nothing")
	assert_bool(_history.has_undo()).is_false()
	assert_bool(_edits.has_unsaved_changes()).is_false()

func test_creates_files_once() -> void:
	var page: AdventurePage = _page("New")
	assert_bool(_edits.create_file(page, NEW_FILE)).is_true()
	assert_str(page.resource_path).is_equal(NEW_FILE)
	assert_bool(FileAccess.file_exists(NEW_FILE)).is_true()
	assert_bool(_edits.create_file(_page("Again"), NEW_FILE)).is_false()
	await assert_error(func() -> void: _edits.create_file(_page("Again"), NEW_FILE)).is_push_error("%s exists already" % NEW_FILE)

func _page(title: String) -> AdventurePage:
	var page: AdventurePage = AdventurePage.new()
	page.title = title
	return page
