extends GdUnitTestSuite

## The debug panel's log collects lines once and keeps only the newest; it colours them and turns paths and IDs into links.

const DEBUG_PANEL: GDScript = preload("uid://du6eu37qg1k3p")  # debug_panel.gd

func test_collects_lines_once() -> void:
	var buffer: LogBuffer = LogBuffer.new()
	buffer._log_message("story: entered\n", false)
	buffer._log_message("oops", true)
	buffer._log_error("f", "a.gd", 3, "code", "", false, Logger.ERROR_TYPE_WARNING, [] as Array[ScriptBacktrace])
	var lines: Array[Dictionary] = buffer.take()
	assert_array(lines.map(func(line: Dictionary) -> int: return line.kind)).contains_exactly(
		[LogBuffer.Kind.MESSAGE, LogBuffer.Kind.ERROR, LogBuffer.Kind.WARNING]
	)
	assert_str(lines[0].text as String).is_equal("story: entered")
	assert_str(lines[2].text as String).is_equal("WARNING: code (a.gd:3, f)")
	assert_array(buffer.take()).is_empty()

func test_keeps_the_newest() -> void:
	var buffer: LogBuffer = LogBuffer.new()
	for index: int in LogBuffer.LIMIT + 5: buffer._log_message(str(index), false)
	var lines: Array[Dictionary] = buffer.take()
	assert_array(lines).has_size(LogBuffer.LIMIT)
	assert_str(lines.back().text as String).is_equal(str(LogBuffer.LIMIT + 4))

func test_links_paths_and_ids() -> void:
	var line: String = DEBUG_PANEL.format_line("12:00:00 story: entered \"[Ruin]\" (uid://abc::Resource_x)\n   At: res://a.gd:13:f()", LogBuffer.Kind.MESSAGE)
	assert_str(line).contains("[b]story[/b]").contains("[lb]Ruin]").contains("[url=uid://abc::Resource_x]").contains("[url=res://a.gd:13:f]")

func test_names_content() -> void:
	assert_str(DEBUG_PANEL._label(Rules.STRENGTH)).is_equal(Rules.STRENGTH.descriptor)
	assert_str(DEBUG_PANEL._link("user://gone.tres")).contains("(gone)")
	assert_str(DEBUG_PANEL._link(ResourceId.of(Rules.d6))).contains("[url=%s]" % ResourceId.of(Rules.d6))
