extends GdUnitTestSuite

## The debug panel's log collects lines once, keeps only the newest; its state view names content instead of showing IDs.

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

func test_state_names_content() -> void:
	var text: String = DEBUG_PANEL._to_text({breath_dice = {ResourceId.of(Rules.d6): 2}, places = [ResourceId.of(Rules.STRENGTH)], gone = "user://gone.tres"}, 0)
	assert_str(text).contains("d6: 2").contains("places: [strength]").contains("gone: user://gone.tres (gone)")
