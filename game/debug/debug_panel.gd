extends CanvasLayer

## Debug builds only, toggled with F10 ("debug_panel"): what was logged (prints, warnings, errors; [LogBuffer]) and how the story stands
## ([method Story.get_save], content by name). Built in code: a developer overlay, not part of the game's look.

const STATE_REFRESH_SECONDS: float = 0.5
const FONT_SIZE: int = 12
const KIND_COLORS: Dictionary[LogBuffer.Kind, Color] = {
	LogBuffer.Kind.MESSAGE: Color(0.85, 0.85, 0.85),
	LogBuffer.Kind.WARNING: Color(1.0, 0.8, 0.3),
	LogBuffer.Kind.ERROR: Color(1.0, 0.4, 0.4),
}

var _buffer: LogBuffer = LogBuffer.new()
## Everything collected from [member _buffer], at most [constant LogBuffer.LIMIT]
var _lines: Array[Dictionary] = []
var _panel: PanelContainer
var _tabs: TabContainer
var _filter: LineEdit
var _log: RichTextLabel
var _state: RichTextLabel
var _since_state_refresh: float = 0.0

func _ready() -> void:
	if not OS.is_debug_build():
		queue_free()
		return
	layer = 128
	OS.add_logger(_buffer)
	_build()
	_panel.hide()

func _exit_tree() -> void:
	if OS.is_debug_build(): OS.remove_logger(_buffer)

func _unhandled_key_input(event: InputEvent) -> void:
	if not event.is_action_released("debug_panel"): return
	get_viewport().set_input_as_handled()
	_panel.visible = not _panel.visible
	_since_state_refresh = STATE_REFRESH_SECONDS

func _process(delta: float) -> void:
	var new_lines: Array[Dictionary] = _buffer.take()
	if not new_lines.is_empty():
		_lines.append_array(new_lines)
		if _lines.size() > LogBuffer.LIMIT:
			_lines = _lines.slice(-LogBuffer.LIMIT)
			_render_log()
		else: for line: Dictionary in new_lines: _append_line(line)
	if not _panel.visible or _tabs.current_tab != _state.get_index(): return
	_since_state_refresh += delta
	if _since_state_refresh < STATE_REFRESH_SECONDS: return
	_since_state_refresh = 0.0
	var state: String = _describe_state()
	if state == _state.text: return
	var scroll: float = _state.get_v_scroll_bar().value
	_state.text = state
	_state.get_v_scroll_bar().set_deferred("value", scroll)

func _render_log() -> void:
	_log.clear()
	for line: Dictionary in _lines: _append_line(line)

func _append_line(line: Dictionary) -> void:
	var text: String = line.text
	if not _filter.text.is_empty() and not text.containsn(_filter.text): return
	_log.push_color(KIND_COLORS[line.kind as LogBuffer.Kind])
	_log.add_text(text)
	_log.pop()
	_log.newline()

func _describe_state() -> String:
	var story: Story = get_tree().current_scene as Story
	if story == null: return "No story running."
	if story.get_protagonist() == null: return "The story hasn't started."
	var data: Dictionary = story.get_save()
	# The log tab shows it as it happens
	data.erase("journal")
	var run: String = story.run if not story.run.is_empty() else "none (not saved)"
	return "Run: %s\nCan save now: %s\n\n%s" % [run, "yes" if story.can_save() else "no", _to_text(data, 0)]

## Indented "key: value" lines, IDs as names
static func _to_text(value: Variant, depth: int) -> String:
	var indent: String = "  ".repeat(depth)
	if value is Dictionary:
		var dictionary: Dictionary = value
		if dictionary.is_empty(): return "{}"
		var text: String = ""
		for key: Variant in dictionary: text += "\n%s%s: %s" % [indent, _name(key), _to_text(dictionary[key], depth + 1)]
		return text
	if value is Array:
		var array: Array = value
		if array.all(func(item: Variant) -> bool: return not item is Dictionary and not item is Array):
			return "[%s]" % ", ".join(array.map(func(item: Variant) -> String: return _name(item)))
		var text: String = ""
		for item: Variant in array: text += "\n%s- %s" % [indent, _to_text(item, depth + 1).strip_edges()]
		return text
	return _name(value)

## A [ResourceId] as its title, description or name (its file's name if it has none); anything else as it is
static func _name(value: Variant) -> String:
	if not value is String: return str(value)
	var text: String = value
	if not (text.begins_with("uid://") or text.begins_with("res://") or text.begins_with("user://")): return text
	var resource: Resource = ResourceId.find(text)
	if resource == null: return "%s (gone)" % text
	for property: String in ["title", "description", "name"]:
		var label: Variant = resource.get(property)
		if label is String and not (label as String).is_empty(): return label
	return resource.resource_path.get_file().get_basename()

func _build() -> void:
	_panel = PanelContainer.new()
	_panel.set_anchors_and_offsets_preset(Control.PRESET_RIGHT_WIDE)
	_panel.anchor_left = 0.55
	_panel.offset_left = 0.0
	var background: StyleBoxFlat = StyleBoxFlat.new()
	background.bg_color = Color(0.05, 0.05, 0.07, 0.9)
	background.set_content_margin_all(6.0)
	_panel.add_theme_stylebox_override("panel", background)
	add_child(_panel)
	_tabs = TabContainer.new()
	_tabs.add_theme_font_size_override("font_size", FONT_SIZE)
	_panel.add_child(_tabs)

	var log_tab: VBoxContainer = VBoxContainer.new()
	log_tab.name = "Log"
	_tabs.add_child(log_tab)
	var bar: HBoxContainer = HBoxContainer.new()
	log_tab.add_child(bar)
	_filter = LineEdit.new()
	_filter.placeholder_text = "Filter"
	_filter.clear_button_enabled = true
	_filter.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_filter.add_theme_font_size_override("font_size", FONT_SIZE)
	_filter.text_changed.connect(func(_text: String) -> void: _render_log())
	bar.add_child(_filter)
	var clear: Button = Button.new()
	clear.text = "Clear"
	clear.add_theme_font_size_override("font_size", FONT_SIZE)
	clear.pressed.connect(func() -> void:
		_lines.clear()
		_log.clear()
	)
	bar.add_child(clear)
	_log = _create_text()
	log_tab.add_child(_log)

	_state = _create_text()
	_state.name = "State"
	_state.scroll_following = false
	_tabs.add_child(_state)

func _create_text() -> RichTextLabel:
	var label: RichTextLabel = RichTextLabel.new()
	label.bbcode_enabled = false
	label.scroll_following = true
	label.selection_enabled = true
	label.context_menu_enabled = true
	label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("normal_font_size", FONT_SIZE)
	return label
