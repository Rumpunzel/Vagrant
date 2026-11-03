extends Node

## Debug builds only, F10 ("debug_panel"): a window (it pops out into one of its own, [PopoutWindow]) with what was logged (prints,
## warnings, errors; [LogBuffer]) and how the story stands ([method Story.get_save] and the protagonist). Script paths and content IDs are
## links that open in the editor the game runs from ([GameDebuggerLinks]). Built in code: a developer tool, not the game's look.

const POPOUT_WINDOW: PackedScene = preload("uid://d1kbbfs6j3ty6")  # popout_window.tscn
const SIZE: Vector2 = Vector2(640, 760)
const STATE_REFRESH_SECONDS: float = 0.5
const FONT_SIZE: int = 14
const ICON_SIZE: int = 18
const DIM: Color = Color(0.55, 0.58, 0.62)
const HEADING: Color = Color(0.95, 0.8, 0.5)
const LINK: Color = Color(0.5, 0.75, 1.0)
const KIND_COLORS: Dictionary[LogBuffer.Kind, Color] = {
	LogBuffer.Kind.MESSAGE: Color(0.88, 0.88, 0.88),
	LogBuffer.Kind.WARNING: Color(1.0, 0.8, 0.3),
	LogBuffer.Kind.ERROR: Color(1.0, 0.45, 0.45),
}
const GOOD: Color = Color(0.55, 0.85, 0.6)
const START_ICON: Texture2D = preload("uid://bi61e6du7f1m0")  # play.svg
const LOAD_ICON: Texture2D = preload("uid://d3nxl0j06xumb")  # arrow-path.svg
const ENTER_ICON: Texture2D = preload("uid://d3og4m8anwfes")  # map-pin.svg
const CHOOSE_ICON: Texture2D = preload("uid://drgkk842oa5ja")  # cursor-arrow-rays.svg
const STAGE_ICON: Texture2D = preload("uid://dwkyq7qlsoqtp")  # flag.svg
const MOVE_ICON: Texture2D = preload("uid://cva2ujh4tfewg")  # arrows-right-left.svg
const FIGHT_ICON: Texture2D = preload("uid://5vyvb0dueieq")  # crossed-swords.svg
const CAMP_ICON: Texture2D = preload("uid://qbxnlgxl1qta")  # campfire.svg
const BREATH_ICON: Texture2D = preload("uid://bhp2ma6kjfmk")  # information-circle.svg
const INFO_ICON: Texture2D = preload("uid://c8itegtg34bpi")  # chat-bubble-left.svg
const WARNING_ICON: Texture2D = preload("uid://drwku5rg0je33")  # exclamation-triangle.svg
const ERROR_ICON: Texture2D = preload("uid://cap0rc53s8cmp")  # x-circle.svg

var _buffer: LogBuffer = LogBuffer.new()
## { bbcode, search (its plain text) } of each line, at most [constant LogBuffer.LIMIT]
var _lines: Array[Dictionary] = []
var _story: Story
var _window: PopoutWindow
var _tabs: TabContainer
var _filter: LineEdit
var _log: RichTextLabel
var _state: RichTextLabel
var _since_state_refresh: float = 0.0

func _ready() -> void:
	if not OS.is_debug_build():
		queue_free()
		return
	OS.add_logger(_buffer)
	_build()

func _exit_tree() -> void:
	if OS.is_debug_build(): OS.remove_logger(_buffer)

func _unhandled_key_input(event: InputEvent) -> void:
	if not event.is_action_released("debug_panel"): return
	get_viewport().set_input_as_handled()
	toggle()

## Shows or hides it; popped out, it is minimized instead
func toggle() -> void:
	_since_state_refresh = STATE_REFRESH_SECONDS
	if _window.force_native:
		_window.mode = Window.MODE_WINDOWED if _window.mode == Window.MODE_MINIMIZED else Window.MODE_MINIMIZED
	elif _window.visible: _window.hide()
	else:
		var screen: Vector2 = get_viewport().get_visible_rect().size
		_window.popup(Rect2i(Vector2i(int(screen.x - SIZE.x - 16.0), 16), Vector2i(SIZE)))

func _process(delta: float) -> void:
	_take_buffer()
	_watch_story()
	if not _window.visible or _tabs.current_tab != _state.get_index(): return
	_since_state_refresh += delta
	if _since_state_refresh < STATE_REFRESH_SECONDS: return
	_since_state_refresh = 0.0
	var state: String = _describe_state()
	if state == _state.text: return
	var scroll: float = _state.get_v_scroll_bar().value
	_state.text = state
	_state.get_v_scroll_bar().set_deferred("value", scroll)

#region Log

## The journal of the story running now, to show its entries as they are written
func _watch_story() -> void:
	var story: Story = get_tree().current_scene as Story
	if story == _story: return
	if _story != null and is_instance_valid(_story) and _story.journal.written.is_connected(_on_journal_written):
		_story.journal.written.disconnect(_on_journal_written)
	_story = story
	if _story == null: return
	# Started in the frame the scene changed: its first entries are written already
	for entry: Dictionary in _story.journal.entries: _add(format_entry(entry))
	_story.journal.written.connect(_on_journal_written)

func _on_journal_written(entry: Dictionary) -> void:
	# What was logged before it comes first
	_take_buffer()
	_add(format_entry(entry))

func _take_buffer() -> void:
	var journal_line: RegEx = RegEx.create_from_string("^\\d\\d:\\d\\d:\\d\\d %s: " % StoryJournal.LOG_CATEGORY)
	for line: Dictionary in _buffer.take():
		var text: String = line.text
		# Shown from the journal itself
		if journal_line.search(text) != null: continue
		_add(format_message(text, line.kind as LogBuffer.Kind))

## A line, with the time it came in
func _add(bbcode: String) -> void:
	var time: String = "[color=#%s][font_size=%d]%s[/font_size][/color]  " % [DIM.to_html(false), FONT_SIZE - 2, Time.get_time_string_from_system()]
	var line: Dictionary = {bbcode = time + bbcode, search = StoryJournal.to_plain_text(bbcode)}
	_lines.append(line)
	if _lines.size() > LogBuffer.LIMIT:
		_lines = _lines.slice(-LogBuffer.LIMIT)
		_render_log()
	else: _append_line(line)

func _render_log() -> void:
	_log.clear()
	for line: Dictionary in _lines: _append_line(line)

func _append_line(line: Dictionary) -> void:
	if not _filter.text.is_empty() and not (line.search as String).containsn(_filter.text): return
	_log.append_text((line.bbcode as String) + "\n")

## A journal entry ([StoryJournal]) with an icon, names as links, numbers bold, outcomes coloured
static func format_entry(entry: Dictionary) -> String:
	match entry.get("type"):
		"start": return "%s Started %s, seed %s" % [_icon(START_ICON), _link(entry.adventure as String), _bold(str(entry.seed))]
		"load": return "%s Loaded run %s" % [_icon(LOAD_ICON), _bold(_escaped(entry.run as String))]
		"enter": return "%s [b]%s[/b]" % [_icon(ENTER_ICON, HEADING), _link(entry.page as String)]
		"choose": return "%s [i]%s[/i]" % [_icon(CHOOSE_ICON, LINK), _link(entry.decision as String)]
		"chance":
			var came_up: bool = entry.came_up
			return "%s %s %s" % [_icon(Rules.d6.icon_filled), _link(entry.condition as String), _outcome("came up" if came_up else "missed", came_up)]
		"roll": return _format_roll(entry)
		"stage":
			return "%s %s: %s → %s" % [_icon(STAGE_ICON), _link(entry.subject as String), _escaped(entry.track as String), _bold(_escaped(entry.stage as String))]
		"move":
			var places: Array[String] = []
			for place: Variant in entry.places as Array: places.append(_link(place as String))
			return "%s %s moves to %s" % [_icon(MOVE_ICON), _link(entry.encounter as String), ", ".join(places)]
		"injury":
			return "%s %s is hurt for %s (%s in all)" % [
				_icon(Injury.ICON, KIND_COLORS[LogBuffer.Kind.ERROR]), _actor(entry), _bold(str(int(entry.magnitude))), _bold(str(int(entry.total)))
			]
		"breath_lost":
			var dice: String = ""
			for die: Variant in entry.dice as Array: dice += _die_icon(die as String)
			return "%s %s loses %s(%s left)" % [_icon(BREATH_ICON), _actor(entry), dice, _bold(str(int(entry.left)))]
		"breath_caught":
			var recovered: String = ""
			var saved: Dictionary = entry.recovered
			for die: String in saved: for _index: int in int(saved[die]): recovered += _die_icon(die)
			var exhausted: String = ""
			for die: Variant in entry.exhaustion as Array: exhausted += _die_icon(die as String, Color(0.4, 0.4, 0.4))
			return "%s %s catches breath: %s, exhausted %s" % [_icon(CAMP_ICON), _actor(entry), recovered, exhausted]
		"exchange": return _format_exchange(entry)
	return _escaped(str(entry))

static func _format_roll(entry: Dictionary) -> String:
	var attribute: CharacterAttribute = ResourceId.find(entry.attribute as String) as CharacterAttribute
	var faces: Array[String] = []
	for face: Variant in entry.dice as Array: faces.append(_bold(str(int(face))))
	var outcome: String = entry.outcome
	var icon: String = _icon(attribute.icon, attribute.color) + " " + _escaped(attribute.descriptor) if attribute != null else _icon(Rules.d6.icon_filled)
	return "%s rolls %s: %s by %s, for %s" % [
		icon, " ".join(faces), _outcome(outcome.to_lower(), outcome == "SUCCESS", outcome == "DRAW"), _bold(str(int(entry.margin))), _link(entry.decision as String)
	]

## The exchange's result, then what was told about it below
static func _format_exchange(entry: Dictionary) -> String:
	var outcome: String = entry.outcome
	var text: String = "%s Exchange %s: %s vs %s, %s" % [
		_icon(FIGHT_ICON, HEADING), _bold(str(int(entry.number))), _bold(_escaped(entry.get("first", "") as String)),
		_bold(_escaped(entry.get("second", "") as String)), _outcome(outcome.to_lower(), outcome == "WON", outcome != "LOST"),
	]
	for told: Variant in entry.get("told", []) as Array: text += "\n[indent][color=#%s]%s[/color][/indent]" % [DIM.to_html(false), _escaped(told as String)]
	return text

## A line logged by anything else: errors and warnings in their colour, the rest dim; "At: …" lines indented; paths as links
static func format_message(text: String, kind: LogBuffer.Kind) -> String:
	var color: Color = KIND_COLORS[kind] if kind != LogBuffer.Kind.MESSAGE else DIM
	var lines: Array[String] = []
	for line: String in text.split("\n"):
		var linked: String = _linked(_escaped(line.strip_edges()))
		if line.strip_edges().begins_with("At:"): lines.append("[indent][color=#%s]%s[/color][/indent]" % [DIM.to_html(false), linked])
		else: lines.append("[color=#%s]%s[/color]" % [color.to_html(false), linked])
	var icons: Dictionary[LogBuffer.Kind, Texture2D] = {LogBuffer.Kind.MESSAGE: INFO_ICON, LogBuffer.Kind.WARNING: WARNING_ICON, LogBuffer.Kind.ERROR: ERROR_ICON}
	return "%s %s" % [_icon(icons[kind], color), "\n".join(lines)]

static func _linked(escaped: String) -> String:
	return RegEx.create_from_string(GameDebuggerLinks.PATTERN).sub(escaped, "[url=$0][color=#%s]$0[/color][/url]" % LINK.to_html(false), true)

static func _actor(entry: Dictionary) -> String: return _bold(_escaped(entry.actor as String))

static func _outcome(text: String, good: bool, middling: bool = false) -> String:
	var color: Color = GOOD if good else KIND_COLORS[LogBuffer.Kind.WARNING] if middling else KIND_COLORS[LogBuffer.Kind.ERROR]
	return "[b][color=#%s]%s[/color][/b]" % [color.to_html(false), text]

static func _bold(text: String) -> String: return "[b]%s[/b]" % text

## The die type named [param die_name] ("d6") as its icon
static func _die_icon(die_name: String, color: Color = Color.WHITE) -> String:
	for die_type: DieType in Rules.BREATH_DICE: if str(die_type) == die_name: return _icon(die_type.icon_filled, color) + " "
	return die_name + " "

#endregion

#region State

func _describe_state() -> String:
	var story: Story = get_tree().current_scene as Story
	if story == null: return "[i]No story running.[/i]"
	var protagonist: Character = story.get_protagonist()
	if protagonist == null: return "[i]The story hasn't started.[/i]"
	var save: Dictionary = story.get_save()
	var random: Dictionary = save.random
	var text: String = _heading("Story")
	var chances: Array[String] = []
	var saved_chances: Dictionary = save.chance_rolls
	for id: String in saved_chances: chances.append("%s %s" % [_link(id), _yes_no(saved_chances[id] as bool)])
	var way_back: Array[String] = []
	for id: String in save.page_stack as Array: way_back.append(_link(id))
	var area: String = _link(save.entered_area as String) + (" [color=#%s](first time)[/color]" % DIM.to_html(false) if save.first_time_in_area else "")
	text += _table([
		["Run", story.run if not story.run.is_empty() else _dim("not saved")],
		["Can save", _yes_no(story.can_save())],
		["Seed", str(random.seed)],
		["Page", _link(save.page as String)],
		["Location", _link(save.location as String)],
		["Area entered", area],
		["Host", _link(save.host as String)],
		["Encounter", _link(save.encounter as String)],
		["Way back", " › ".join(way_back) if not way_back.is_empty() else _dim("—")],
		["Chances", "\n".join(chances) if not chances.is_empty() else _dim("—")],
	])
	text += _describe_protagonist(protagonist)
	text += _describe_world(save.world as Dictionary)
	text += _describe_monsters(save.monsters as Array)
	return text

func _describe_protagonist(protagonist: Character) -> String:
	var profile: CharacterProfile = protagonist.character_profile
	var text: String = _heading("%s %s" % [_escaped(profile.name), _dim(_escaped(profile.title))])
	var rows: Array[Array] = []
	for attribute: CharacterAttribute in Rules.ATTRIBUTES:
		var score: int = protagonist.get_score(attribute)
		var base: int = profile.get_attribute_score(attribute)
		var value: String = "[b]%d[/b]" % score + (_dim(" (rolled %d)" % base) if base != score else "")
		rows.append([_icon(attribute.icon, attribute.color) + " " + _escaped(attribute.descriptor), value])
	var breath: String = ""
	for die_type: DieType in Rules.BREATH_DICE:
		if protagonist.exhaustion.has(die_type):
			breath += _icon(die_type.icon_blank, Color(0.35, 0.35, 0.35)) + " "
			continue
		var have: int = protagonist.breath_dice.get(die_type, 0)
		for _index: int in have: breath += _icon(die_type.icon_filled) + " "
		for _index: int in Rules.BREATH_DICE[die_type] - have: breath += _icon(die_type.icon_blank) + " "
	rows.append(["Breath dice", breath + _dim("(%d)" % protagonist.get_breath_dice_count())])
	var exhausted: Array[String] = []
	for die_type: DieType in protagonist.exhaustion: exhausted.append(str(die_type))
	rows.append(["Exhausted", ", ".join(exhausted) if not exhausted.is_empty() else _dim("—")])
	rows.append(["Injuries", _injuries(protagonist.get_save().injuries as Array)])
	rows.append(["Gear", _gear(protagonist)])
	var items: Array[String] = []
	for item: ItemProfile in protagonist.items: items.append("%s %s ×%d" % [_icon(item.icon), _escaped(item.name), protagonist.items[item]])
	rows.append(["Items", "\n".join(items) if not items.is_empty() else _dim("—")])
	var origins: Array[String] = []
	for origin: Origin in profile.origins: if origin != null: origins.append(_link(ResourceId.of(origin), _label(origin)))
	rows.append(["Origins", ", ".join(origins)])
	return text + _table(rows)

func _describe_world(world: Dictionary) -> String:
	var text: String = _heading("World")
	var rows: Array[Array] = []
	var stages: Dictionary = world.stages
	for subject: String in stages:
		var tracks: Dictionary = stages[subject]
		for track: String in tracks: rows.append([_link(subject), "%s → [b]%s[/b]" % [_escaped(track), _escaped(tracks[track] as String)]])
	var places: Dictionary = world.places
	for encounter: String in places:
		var locations: Array[String] = []
		for location: String in places[encounter] as Array: locations.append(_link(location))
		rows.append([_link(encounter), "at " + (", ".join(locations) if not locations.is_empty() else _dim("nowhere"))])
	return text + (_table(rows) if not rows.is_empty() else _dim("Every track at its first stage, every encounter where it starts.") + "\n")

func _describe_monsters(monsters: Array) -> String:
	var text: String = _heading("Monsters")
	if monsters.is_empty(): return text + _dim("None met yet.") + "\n"
	var rows: Array[Array] = []
	for monster: Dictionary in monsters:
		var state: Dictionary = monster.state
		var breath: String = ""
		var saved_breath: Dictionary = state.breath_dice
		for id: String in saved_breath:
			var die_type: DieType = ResourceId.find(id) as DieType
			for _index: int in int(saved_breath[id]): breath += _icon(die_type.icon_filled if die_type != null else null) + " "
		var status: String = "[color=#%s]dead[/color]" % KIND_COLORS[LogBuffer.Kind.ERROR].to_html(false) if state.dead \
			else "[color=#%s]beaten[/color]" % KIND_COLORS[LogBuffer.Kind.WARNING].to_html(false) if state.incapacitated else "can fight"
		var where: String = _link(monster.owner as String) + (" at " + _link(monster.location as String) if not (monster.location as String).is_empty() else "")
		rows.append(["%s #%d" % [_link(monster.profile as String), int(monster.index)], "%s\n%s %s\n%s" % [where, breath, _injuries(state.injuries as Array), status]])
	return text + _table(rows)

func _gear(actor: Actor) -> String:
	var lines: Array[String] = []
	var gear: Array[Equipment] = []
	gear.append_array(actor.weapons)
	gear.append_array(actor.armor)
	gear.append_array(actor.shields)
	for equipment: Equipment in gear:
		var notes: Array[String] = []
		if not equipment.marked_faces.is_empty(): notes.append("marked %s" % ", ".join(equipment.marked_faces.map(func(face: int) -> String: return str(face))))
		if equipment.ruined: notes.append("ruined")
		if equipment.dropped: notes.append("dropped")
		lines.append(_escaped(equipment.get_equipment_name()) + (" " + _dim("(%s)" % ", ".join(notes)) if not notes.is_empty() else ""))
	return "\n".join(lines) if not lines.is_empty() else _dim("—")

static func _injuries(magnitudes: Array) -> String:
	if magnitudes.is_empty(): return _dim("unhurt")
	var icons: Array[String] = []
	for magnitude: Variant in magnitudes: icons.append(Injury.to_bbcode(int(magnitude), ICON_SIZE))
	return " ".join(icons)

static func _heading(title: String) -> String:
	return "\n[font_size=%d][b][color=#%s]%s[/color][/b][/font_size]\n" % [FONT_SIZE + 3, HEADING.to_html(false), title]

static func _table(rows: Array) -> String:
	var text: String = "[table=2]"
	for row: Array in rows:
		text += "[cell padding=0,3,16,3][color=#%s]%s[/color][/cell][cell expand=1 padding=0,3,0,3]%s[/cell]" % [DIM.to_html(false), row[0], row[1]]
	return text + "[/table]\n"

static func _icon(texture: Texture2D, color: Color = Color.WHITE) -> String:
	if texture == null: return ""
	return "[img color=#%s width=%d height=%d valign=center]%s[/img]" % [color.to_html(), ICON_SIZE, ICON_SIZE, texture.resource_path]

static func _yes_no(yes: bool) -> String:
	var color: Color = KIND_COLORS[LogBuffer.Kind.ERROR] if not yes else GOOD
	return "[color=#%s]%s[/color]" % [color.to_html(false), "yes" if yes else "no"]

static func _dim(text: String) -> String: return "[color=#%s]%s[/color]" % [DIM.to_html(false), text]

## A [ResourceId] by name, as a link to open it in the editor; [param label] instead of its name
static func _link(id: String, label: String = "") -> String:
	if id.is_empty(): return _dim("—")
	var resource: Resource = ResourceId.find(id)
	if resource == null: return "[color=#%s]%s (gone)[/color]" % [KIND_COLORS[LogBuffer.Kind.ERROR].to_html(false), id]
	var text: String = _escaped(label if not label.is_empty() else _label(resource))
	return "[url=%s][color=#%s]%s[/color][/url]" % [id, LINK.to_html(false), text]

## [method StoryJournal.label], else its file's name (its ID in there)
static func _label(resource: Resource) -> String:
	var label: String = StoryJournal.label(resource)
	if not label.is_empty(): return label
	var path: String = resource.resource_path
	return path.get_file().get_basename() if not path.contains(ResourceId.SEPARATOR) else path.get_slice(ResourceId.SEPARATOR, 1)

static func _escaped(text: String) -> String: return text.replace("[", "[lb]")

#endregion

func _build() -> void:
	_window = POPOUT_WINDOW.instantiate()
	_window.unresizable = false
	var content: MarginContainer = MarginContainer.new()
	content.custom_minimum_size = SIZE
	# Room for the window's pop-out and close buttons
	content.add_theme_constant_override("margin_top", 44)
	var background: StyleBoxFlat = StyleBoxFlat.new()
	background.bg_color = Color(0.06, 0.06, 0.08, 0.94)
	background.set_corner_radius_all(6)
	var panel: PanelContainer = PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.add_theme_stylebox_override("panel", background)
	panel.add_child(content)
	panel.name = "Debug"
	_tabs = TabContainer.new()
	_tabs.add_theme_font_size_override("font_size", FONT_SIZE)
	content.add_child(_tabs)

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
	_window.add(panel)
	add_child(_window)

func _create_text() -> RichTextLabel:
	var label: RichTextLabel = RichTextLabel.new()
	label.bbcode_enabled = true
	label.scroll_following = true
	label.selection_enabled = true
	label.context_menu_enabled = true
	label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("normal_font_size", FONT_SIZE)
	label.add_theme_font_size_override("bold_font_size", FONT_SIZE)
	label.add_theme_constant_override("line_separation", 3)
	label.meta_clicked.connect(func(meta: Variant) -> void: GameDebuggerLinks.open(str(meta)))
	label.meta_hover_started.connect(func(_meta: Variant) -> void: label.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND)
	label.meta_hover_ended.connect(func(_meta: Variant) -> void: label.mouse_default_cursor_shape = Control.CURSOR_IBEAM)
	return label
