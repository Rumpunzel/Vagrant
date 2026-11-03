extends GdUnitTestSuite

## The debug panel's log collects lines once and keeps only the newest; it colours them and turns paths and IDs into links.

func test_collects_lines_once() -> void:
	var buffer: LogBuffer = LogBuffer.new()
	buffer._log_message("story: entered\n", false)
	buffer._log_message("oops", true)
	buffer._log_error("f", "a.gd", 3, "code", "", false, Logger.ERROR_TYPE_WARNING, [] as Array[ScriptBacktrace])
	var lines: Array[Dictionary] = buffer.take()
	assert_array(lines.map(func(line: Dictionary) -> int: return line.kind)).contains_exactly(
		[LogBuffer.Kind.MESSAGE, LogBuffer.Kind.ERROR, LogBuffer.Kind.WARNING]
	)
	assert_str(lines[0].text).is_equal("story: entered")
	assert_str(lines[2].text).is_equal("WARNING: code (a.gd:3, f)")
	assert_array(buffer.take()).is_empty()

func test_keeps_the_newest() -> void:
	var buffer: LogBuffer = LogBuffer.new()
	for index: int in LogBuffer.LIMIT + 5: buffer._log_message(str(index), false)
	var lines: Array[Dictionary] = buffer.take()
	assert_array(lines).has_size(LogBuffer.LIMIT)
	assert_str(lines.back().text).is_equal(str(LogBuffer.LIMIT + 4))

func test_messages_link_paths() -> void:
	var line: String = GameDebugPanel.format_message("Loading [Ruin] uid://abc::Resource_x\n   At: res://a.gd:13:f()", LogBuffer.Kind.ERROR)
	assert_str(line).contains("[lb]Ruin]").contains("[url=uid://abc::Resource_x]").contains("[indent]").contains("[url=res://a.gd:13:f]")

func test_entries_by_name_with_numbers_bold() -> void:
	var entry: Dictionary = {type = "injury", actor = "Lurker", magnitude = 7.0, total = 7.0}
	assert_str(GameDebugPanel.format_entry(entry)).contains("[b]Lurker[/b]").contains("[b]7[/b]").contains(Injury.ICON.resource_path)
	var exchange: Dictionary = {type = "exchange", number = 1, first = "You", second = "Lurker", outcome = "WON", told = ["You win."]}
	assert_str(GameDebugPanel.format_entry(exchange)).contains("won").contains("[indent]").contains("You win.")
	var enter: Dictionary = {type = "enter", page = ResourceId.of(Rules.STRENGTH)}
	assert_str(GameDebugPanel.format_entry(enter)).contains("[url=%s]" % ResourceId.of(Rules.STRENGTH)).contains(Rules.STRENGTH.descriptor)
	assert_str(GameDebugPanel.format_entry({type = "unknown"})).contains("unknown")

## Each kind of entry the journal writes has its own line
func test_every_journal_entry_type() -> void:
	var source: String = (GameDebugPanel as GDScript).source_code
	var journal: String = (StoryJournal as GDScript).source_code
	for found: RegExMatch in RegEx.create_from_string("type = \"(\\w+)\"").search_all(journal):
		assert_str(source).contains("\"%s\":" % found.get_string(1))

func test_names_content() -> void:
	assert_str(GameDebugPanel._label(Rules.STRENGTH)).is_equal(Rules.STRENGTH.descriptor)
	assert_str(GameDebugPanel._link("user://gone.tres")).contains("(gone)")
	assert_str(GameDebugPanel._link(ResourceId.of(Rules.d6))).contains("[url=%s]" % ResourceId.of(Rules.d6))
