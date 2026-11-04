class_name GameDebugPanel
extends Node

## Debug builds only, F10 ("debug_panel"): a window (it pops out into one of its own, [PopoutWindow]) with what was logged (prints,
## warnings, errors; [LogBuffer]) and how the story stands ([method Story.get_state], the world, the protagonist, the monsters). Script paths and content IDs are
## links that open in the editor the game runs from ([GameDebuggerLinks]). Built in code: a developer tool, not the game's look.

const POPOUT_WINDOW: PackedScene = preload("uid://d1kbbfs6j3ty6")  # popout_window.tscn
const SIZE: Vector2 = Vector2(640, 760)
const STATE_REFRESH_SECONDS: float = 0.5
const FONT_SIZE: int = 14
const ICON_SIZE: int = 18
const TOOLTIP_PICTURE_WIDTH: int = 280
## The tooltip's label doesn't wrap: longer first lines are cut
const TOOLTIP_TEXT_LENGTH: int = 60
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
const DEATH_ICON: Texture2D = preload("uid://bjnuqyclma3kc")  # cross-mark.svg
const SAVE_ICON: Texture2D = preload("uid://dialjvdmxg20f")  # arrow-down-tray.svg
const DELETE_ICON: Texture2D = preload("uid://7foj2ni8yr6v")  # trash.svg
const BUG_ICON: Texture2D = preload("uid://buehwfr6g2myk")  # bug-ant.svg
const FOLDER_ICON: Texture2D = preload("uid://dbg5e7ualqfgs")  # folder-open.svg
const BUG_REPORTS: String = "user://bug_reports"
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
var _runs: VBoxContainer
var _save_button: Button
var _restart_button: Button
var _seed_field: LineEdit

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
		var kind: LogBuffer.Kind = line.kind
		_add(format_message(text, kind))

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
	if not _filter.text.is_empty() and not _text(line, "search").containsn(_filter.text): return
	_log.append_text(_text(line, "bbcode") + "\n")

## A journal entry ([StoryJournal]) with an icon, names as links, numbers bold, outcomes coloured
static func format_entry(entry: Dictionary) -> String:
	match entry.get("type"):
		"start": return "%s Started %s, seed %s" % [_icon(START_ICON), _link(_text(entry, "adventure")), _bold(str(entry.seed))]
		"load": return "%s Loaded run %s" % [_icon(LOAD_ICON), _bold(_escaped(_text(entry, "run")))]
		"enter": return "%s [b]%s[/b]" % [_icon(ENTER_ICON, HEADING), _link(_text(entry, "page"))]
		"choose": return "%s [i]%s[/i]" % [_icon(CHOOSE_ICON, LINK), _link(_text(entry, "decision"))]
		"chance":
			var came_up: bool = entry.came_up
			return "%s %s %s" % [_icon(Rules.d6.icon_filled), _link(_text(entry, "condition")), _outcome("came up" if came_up else "missed", came_up)]
		"roll": return _format_roll(entry)
		"stage":
			return "%s %s: %s → %s" % [_icon(STAGE_ICON), _link(_text(entry, "subject")), _escaped(_text(entry, "track")), _bold(_escaped(_text(entry, "stage")))]
		"move":
			var places: Array[String] = []
			for place: String in _list(entry, "places"): places.append(_link(place))
			return "%s %s moves to %s" % [_icon(MOVE_ICON), _link(_text(entry, "encounter")), ", ".join(places)]
		"injury":
			return "%s %s is hurt for %s (%s in all)" % [
				_icon(Injury.ICON, KIND_COLORS[LogBuffer.Kind.ERROR]), _actor(entry), _bold(str(_number(entry, "magnitude"))), _bold(str(_number(entry, "total")))
			]
		"breath_lost":
			var dice: String = ""
			for die: String in _list(entry, "dice"): dice += _die_icon(die)
			return "%s %s loses %s(%s left)" % [_icon(BREATH_ICON), _actor(entry), dice, _bold(str(_number(entry, "left")))]
		"breath_caught":
			var recovered: String = ""
			var saved: Dictionary = entry.recovered
			for die: String in saved: for _index: int in _number(saved, die): recovered += _die_icon(die)
			var exhausted: String = ""
			for die: String in _list(entry, "exhaustion"): exhausted += _die_icon(die, Color(0.4, 0.4, 0.4))
			return "%s %s catches breath: %s, exhausted %s" % [_icon(CAMP_ICON), _actor(entry), recovered, exhausted]
		"exchange": return _format_exchange(entry)
		"rested": return "%s %s rests: no more exhaustion" % [_icon(CAMP_ICON), _actor(entry)]
		"died": return "%s %s %s" % [_icon(DEATH_ICON, KIND_COLORS[LogBuffer.Kind.ERROR]), _actor(entry), _outcome("died", false)]
	return _escaped(str(entry))

static func _format_roll(entry: Dictionary) -> String:
	var attribute: CharacterAttribute = ResourceId.find(_text(entry, "attribute")) as CharacterAttribute
	var faces: Array[String] = []
	for face: int in _list(entry, "dice"): faces.append(_bold(str(face)))
	var outcome: String = entry.outcome
	var icon: String = _icon(attribute.icon, attribute.color) + " " + _escaped(attribute.descriptor) if attribute != null else _icon(Rules.d6.icon_filled)
	return "%s rolls %s: %s by %s, for %s" % [
		icon, " ".join(faces), _outcome(outcome.to_lower(), outcome == "SUCCESS", outcome == "DRAW"), _bold(str(_number(entry, "margin"))), _link(_text(entry, "decision"))
	]

## The exchange's result, then what was told about it below
static func _format_exchange(entry: Dictionary) -> String:
	var outcome: String = entry.outcome
	var text: String = "%s Exchange %s: %s vs %s, %s" % [
		_icon(FIGHT_ICON, HEADING), _bold(str(_number(entry, "number"))), _bold(_escaped(_text(entry, "first"))),
		_bold(_escaped(_text(entry, "second"))), _outcome(outcome.to_lower(), outcome == "WON", outcome != "LOST"),
	]
	for told: String in _list(entry, "told"): text += "\n[indent][color=#%s]%s[/color][/indent]" % [DIM.to_html(false), _escaped(told)]
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

static func _actor(entry: Dictionary) -> String: return _bold(_escaped(_text(entry, "actor")))

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
	var save: Dictionary = story.get_state()
	var random: Dictionary = save.random
	var run: String = story.run if not story.run.is_empty() else "not saved"
	var text: String = _dim("Run %s · saving %s · seed %s" % [run, _yes_no(story.can_save()), str(random.seed)]) + "\n"
	text += _heading("Story")
	var rows: Array[Array] = []
	var where: String = _link(_text(save, "page"))
	if _text(save, "location") != _text(save, "page"): where += _dim(" at ") + _link(_text(save, "location"))
	if not _text(save, "entered_area").is_empty():
		where += _dim(" · entered ") + _link(_text(save, "entered_area")) + (_dim(" (first time)") if save.first_time_in_area else "")
	rows.append(["Page", where])
	var event: Array[String] = []
	if not _text(save, "host").is_empty(): event.append(_dim("on ") + _link(_text(save, "host")))
	if not _text(save, "encounter").is_empty(): event.append(_dim("encounter ") + _link(_text(save, "encounter")))
	if not event.is_empty(): rows.append(["Event", " · ".join(event)])
	var way_back: Array[String] = []
	for id: String in _list(save, "page_stack"): way_back.append(_link(id))
	if not way_back.is_empty(): rows.append(["Back", _dim(" › ").join(way_back)])
	var chances: Array[String] = []
	var saved_chances: Dictionary = save.chance_rolls
	for id: String in saved_chances: chances.append("%s %s" % [_link(id), _outcome("came up" if _flag(saved_chances, id) else "missed", _flag(saved_chances, id))])
	if not chances.is_empty(): rows.append(["Chances", ", ".join(chances)])
	text += _table(rows)
	text += _describe_protagonist(protagonist)
	text += _describe_world(story.world.get_save())
	text += _describe_monsters(story.get_monsters().get_save())
	return text

func _describe_protagonist(protagonist: Character) -> String:
	var profile: CharacterProfile = protagonist.character_profile
	var origins: Array[String] = []
	for origin: Origin in profile.origins:
		if origin == null: continue
		var id: String = ResourceId.of(origin)
		origins.append(_link(id, _label(origin)) if not id.is_empty() else _escaped(_label(origin)))
	var text: String = _heading("%s %s" % [_escaped(profile.name), _dim(_escaped(profile.title))], ", ".join(origins))
	var rows: Array[Array] = []
	var scores: Array[String] = []
	for attribute: CharacterAttribute in Rules.ATTRIBUTES:
		var score: int = protagonist.get_score(attribute)
		var base: int = profile.get_attribute_score(attribute)
		scores.append("%s [b]%d[/b]%s" % [_icon(attribute.icon, attribute.color), score, _dim("/%d" % base) if base != score else ""])
	rows.append(["Scores", "   ".join(scores)])
	var breath: String = ""
	for die_type: DieType in Rules.BREATH_DICE:
		if protagonist.exhaustion.has(die_type):
			breath += _icon(die_type.icon_blank, Color(0.6, 0.25, 0.25)) + " "
			continue
		var have: int = protagonist.breath_dice.get(die_type, 0)
		for _index: int in have: breath += _icon(die_type.icon_filled) + " "
		for _index: int in Rules.BREATH_DICE[die_type] - have: breath += _icon(die_type.icon_blank, Color(1.0, 1.0, 1.0, 0.35)) + " "
	var injuries: Array[int] = []
	for injury: Injury in protagonist.get_injuries(): injuries.append(injury.magnitude)
	rows.append(["Breath", breath + _dim("(%d)" % protagonist.get_breath_dice_count()) + ("   " + _injuries(injuries) if not injuries.is_empty() else "")])
	var gear: String = _gear(protagonist)
	if not gear.is_empty(): rows.append(["Gear", gear])
	var items: Array[String] = []
	for item: ItemProfile in protagonist.items: items.append("%s%s ×%d" % [_icon(item.icon), _escaped(item.name), protagonist.items[item]])
	if not items.is_empty(): rows.append(["Items", ", ".join(items)])
	return text + _table(rows)

## Only what changed: stages set, encounters moved
func _describe_world(world: Dictionary) -> String:
	var rows: Array[Array] = []
	var stages: Dictionary = world.stages
	for subject: String in stages:
		var tracks: Dictionary = stages[subject]
		var changed: Array[String] = []
		for track: String in tracks: changed.append("%s %s" % [_dim(_escaped(track) + " →"), _bold(_escaped(_text(tracks, track)))])
		rows.append([_link(subject), ", ".join(changed)])
	var places: Dictionary = world.places
	for encounter: String in places:
		var locations: Array[String] = []
		for location: String in _list(places, encounter): locations.append(_link(location))
		rows.append([_link(encounter), _dim("at ") + (", ".join(locations) if not locations.is_empty() else _dim("nowhere"))])
	if rows.is_empty(): return ""
	return _heading("World") + _table(rows)

## One row each: where it belongs, breath, injuries, beaten or dead
func _describe_monsters(monsters: Array) -> String:
	if monsters.is_empty(): return ""
	var rows: Array[Array] = []
	for monster: Dictionary in monsters:
		var state: Dictionary = monster.state
		var breath: String = ""
		var saved_breath: Dictionary = state.breath_dice
		for id: String in saved_breath:
			var die_type: DieType = ResourceId.find(id) as DieType
			for _index: int in _number(saved_breath, id): breath += _icon(die_type.icon_filled if die_type != null else null) + " "
		var status: String = _outcome("dead", false) if state.dead else _outcome("beaten", false, true) if state.incapacitated else ""
		var where: String = _dim("from ") + _link(_text(monster, "owner"))
		if not _text(monster, "location").is_empty(): where += _dim(" at ") + _link(_text(monster, "location"))
		var injuries: Array = _list(state, "injuries")
		var condition: Array[String] = [breath.strip_edges()]
		if not injuries.is_empty(): condition.append(_injuries(injuries))
		if not status.is_empty(): condition.append(status)
		rows.append([_link(_text(monster, "profile")), "%s   %s" % ["  ".join(condition), where]])
	return _heading("Monsters") + _table(rows)

## Inline: "Sword, Buckler (marked 2, 3)"
func _gear(actor: Actor) -> String:
	var pieces: Array[String] = []
	var gear: Array[Equipment] = []
	gear.append_array(actor.weapons)
	gear.append_array(actor.armor)
	gear.append_array(actor.shields)
	for equipment: Equipment in gear:
		var notes: Array[String] = []
		if not equipment.marked_faces.is_empty(): notes.append("marked %s" % ", ".join(equipment.marked_faces.map(func(face: int) -> String: return str(face))))
		if equipment.ruined: notes.append("ruined")
		if equipment.dropped: notes.append("dropped")
		pieces.append(_escaped(equipment.get_equipment_name()) + (" " + _dim("(%s)" % ", ".join(notes)) if not notes.is_empty() else ""))
	return ", ".join(pieces)

static func _injuries(magnitudes: Array) -> String:
	if magnitudes.is_empty(): return _dim("unhurt")
	var icons: Array[String] = []
	for magnitude: int in magnitudes: icons.append(Injury.to_bbcode(magnitude, ICON_SIZE))
	return " ".join(icons)

## [param aside]: dim, after the title
static func _heading(title: String, aside: String = "") -> String:
	return "\n[font_size=%d][b][color=#%s]%s[/color][/b][/font_size]%s\n" % [FONT_SIZE + 2, HEADING.to_html(false), title, "  " + aside if not aside.is_empty() else ""]

static func _table(rows: Array) -> String:
	var text: String = "[table=2]"
	for row: Array in rows:
		text += "[cell padding=0,1,12,1][color=#%s]%s[/color][/cell][cell expand=1 padding=0,1,0,1]%s[/cell]" % [DIM.to_html(false), row[0], row[1]]
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

## A link's preview: its picture (a page's background, a portrait, an icon), its name and the start of its text; none for script paths
static func _tooltip_for(meta: Variant) -> Array[String]:
	var resource: Resource = ResourceId.find(str(meta))
	if resource == null or resource is Script: return []
	var picture: Texture2D = null
	var text: String = ""
	if resource is AdventurePage:
		var page: AdventurePage = resource
		picture = page.background if page.background != null else page.get_area_background()
		text = page.description
	elif resource is AdventureEncounter and (resource as AdventureEncounter).profile != null:
		picture = (resource as AdventureEncounter).profile.get("portrait")
	elif resource.get("portrait") is Texture2D: picture = resource.get("portrait")
	elif resource.get("icon") is Texture2D: picture = resource.get("icon")
	var lines: Array[String] = []
	if picture != null: lines.append("[img=%d]%s[/img]" % [TOOLTIP_PICTURE_WIDTH, picture.resource_path])
	lines.append("[b]%s[/b]" % _escaped(_label(resource)))
	var first_line: String = StoryJournal.to_plain_text(text).get_slice("\n", 0)
	if first_line.length() > TOOLTIP_TEXT_LENGTH: first_line = first_line.left(TOOLTIP_TEXT_LENGTH).strip_edges() + "…"
	if not first_line.is_empty(): lines.append(_dim(_escaped(first_line)))
	lines.append(_dim(str(meta)))
	return ["\n".join(lines)] as Array[String]

## [method StoryJournal.label], else its file's name (its ID in there)
static func _label(resource: Resource) -> String:
	var label: String = StoryJournal.label(resource)
	if not label.is_empty(): return label
	var path: String = resource.resource_path
	return path.get_file().get_basename() if not path.contains(ResourceId.SEPARATOR) else path.get_slice(ResourceId.SEPARATOR, 1)

static func _escaped(text: String) -> String: return text.replace("[", "[lb]")

## Typed reads of saved data (JSON: untyped, numbers are floats)
static func _text(data: Dictionary, key: Variant) -> String:
	var text: String = data.get(key, "")
	return text

static func _number(data: Dictionary, key: Variant) -> int:
	var number: int = data.get(key, 0)
	return number

static func _flag(data: Dictionary, key: Variant) -> bool:
	var flag: bool = data.get(key, false)
	return flag

static func _list(data: Dictionary, key: Variant) -> Array:
	var list: Array = data.get(key, [])
	return list


#endregion

#region Runs

## Lists the saved runs: when each began and was last saved, the page it is on; the running one marked, the others to continue or delete
func _refresh_runs() -> void:
	for child: Node in _runs.get_children():
		_runs.remove_child(child)
		child.queue_free()
	var story: Story = get_tree().current_scene as Story
	var running: String = story.run if story != null else ""
	_save_button.disabled = story == null or not story.can_save()
	_save_button.tooltip_text = "Saves the running story now" if not _save_button.disabled else "Only on a page with nothing going on"
	_restart_button.disabled = story == null or story.get_protagonist() == null
	if story != null and _seed_field.text.is_empty(): _seed_field.text = str(GameRandom.get_seed())
	var runs: Array[String] = SaveGame.get_runs()
	runs.reverse()
	if runs.is_empty(): _runs.add_child(_create_label(_dim("No saved runs.")))
	for run: String in runs:
		var row: HBoxContainer = HBoxContainer.new()
		var save_game: SaveGame = SaveGame.read(run)
		var page: String = _link(_text(save_game.story, "page")) if save_game != null else _dim("unreadable")
		var saved_at: String = save_game.saved_at.get_slice("T", 1) if save_game != null else ""
		var marker: String = _bold("▶ ") if run == running else ""
		var label: RichTextLabel = _create_label("%s%s  %s  %s" % [marker, _escaped(run), _dim("saved " + saved_at), page])
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(label)
		var continue_button: Button = _create_button("Continue", START_ICON, "Goes on with this run")
		continue_button.pressed.connect(func() -> void: Main.continue_run(run))
		row.add_child(continue_button)
		var delete_button: Button = _create_button("", DELETE_ICON, "Deletes this run's save" if run != running else "The running story's save")
		delete_button.disabled = run == running
		delete_button.pressed.connect(func() -> void:
			SaveGame.delete_run(run)
			_refresh_runs()
		)
		row.add_child(delete_button)
		_runs.add_child(row)

func _save_now() -> void:
	var story: Story = get_tree().current_scene as Story
	if story == null or not story.can_save(): return
	# "Play from here" isn't saved by itself; saving it on purpose makes it a run
	if story.run.is_empty(): story.run = SaveGame.start_run()
	var error: Error = SaveGame.capture(story.run, story).write()
	GameLog.write("debug", "saved run %s" % story.run if error == OK else "saving failed: %s" % error_string(error))
	_refresh_runs()

func _restart_with_seed() -> void:
	var seed_text: String = _seed_field.text.strip_edges()
	if not seed_text.is_valid_int():
		push_warning("Not a seed: %s" % seed_text)
		return
	Main.restart_story(seed_text.to_int())

## A folder with the story's save as it is now (also in the middle of a fight) and the log, for a bug report; opened, its path copied
func _write_bug_report() -> void:
	var directory: String = BUG_REPORTS.path_join(Time.get_datetime_string_from_system().replace(":", "-"))
	DirAccess.make_dir_recursive_absolute(directory)
	var story: Story = get_tree().current_scene as Story
	if story != null and story.get_protagonist() != null:
		var save: FileAccess = FileAccess.open(directory.path_join("save.json"), FileAccess.WRITE)
		save.store_string(JSON.stringify({run = story.run, can_save = story.can_save(), story = story.get_save()}, "\t"))
		save.close()
	var log_file: FileAccess = FileAccess.open(directory.path_join("log.txt"), FileAccess.WRITE)
	for line: Dictionary in _lines: log_file.store_line(_text(line, "search"))
	log_file.close()
	var path: String = ProjectSettings.globalize_path(directory)
	DisplayServer.clipboard_set(path)
	GameLog.write("debug", "bug report written to %s (path copied)" % path)
	OS.shell_open(path)

func _open_saves_folder() -> void:
	DirAccess.make_dir_recursive_absolute(SaveGame.DIRECTORY)
	OS.shell_open(ProjectSettings.globalize_path(SaveGame.DIRECTORY))

func _build_runs_tab() -> void:
	var tab: VBoxContainer = VBoxContainer.new()
	tab.name = "Runs"
	_tabs.add_child(tab)
	var bar: HBoxContainer = HBoxContainer.new()
	tab.add_child(bar)
	_save_button = _create_button("Save now", SAVE_ICON, "")
	_save_button.pressed.connect(_save_now)
	bar.add_child(_save_button)
	_seed_field = LineEdit.new()
	_seed_field.placeholder_text = "Seed"
	_seed_field.tooltip_text = "A run's seed (the log's \"Started\" line); the same choices then give the same rolls"
	_seed_field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_seed_field.add_theme_font_size_override("font_size", FONT_SIZE)
	bar.add_child(_seed_field)
	_restart_button = _create_button("Restart", LOAD_ICON, "Starts the adventure again with this seed and the same protagonist")
	_restart_button.pressed.connect(_restart_with_seed)
	bar.add_child(_restart_button)
	var tools: HBoxContainer = HBoxContainer.new()
	tab.add_child(tools)
	var report_button: Button = _create_button("Bug report", BUG_ICON, "Writes the save as it is now and the log into a folder, opens it and copies its path")
	report_button.pressed.connect(_write_bug_report)
	tools.add_child(report_button)
	var folder_button: Button = _create_button("Saves folder", FOLDER_ICON, "Opens the folder the runs are saved in")
	folder_button.pressed.connect(_open_saves_folder)
	tools.add_child(folder_button)
	var refresh_button: Button = _create_button("", LOAD_ICON, "Reads the saved runs again")
	refresh_button.pressed.connect(_refresh_runs)
	tools.add_child(refresh_button)
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	tab.add_child(scroll)
	_runs = VBoxContainer.new()
	_runs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_runs)
	_tabs.tab_changed.connect(func(index: int) -> void:
		if index == tab.get_index(): _refresh_runs()
	)

func _create_button(text: String, icon: Texture2D, tooltip: String) -> Button:
	var button: Button = Button.new()
	button.text = text
	button.icon = icon
	button.tooltip_text = tooltip
	button.expand_icon = false
	button.add_theme_constant_override("icon_max_width", ICON_SIZE)
	button.add_theme_font_size_override("font_size", FONT_SIZE)
	return button

func _create_label(bbcode: String) -> RichTextLabel:
	var label: RichTextLabel = RichTextLabel.new()
	label.bbcode_enabled = true
	label.fit_content = true
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.text = bbcode
	label.add_theme_font_size_override("normal_font_size", FONT_SIZE)
	label.add_theme_font_size_override("bold_font_size", FONT_SIZE)
	label.meta_clicked.connect(func(meta: Variant) -> void: GameDebuggerLinks.open(str(meta)))
	return label

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
	_filter.text_changed.connect(func(_t: String) -> void: _render_log())
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
	_build_runs_tab()
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
	var tooltips: MetaTooltipTrigger = MetaTooltipTrigger.new()
	tooltips.trigger_node = label
	tooltips.origin = TooltipEnums.TooltipOrigin.MOUSE_POSITION_START
	tooltips.offset = Vector2(16.0, 16.0)
	tooltips.overflow_mode = TooltipEnums.OverflowMode.CLAMP
	tooltips.tooltip_for = _tooltip_for
	label.add_child(tooltips)
	label.meta_hover_started.connect(func(_meta: Variant) -> void: label.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND)
	label.meta_hover_ended.connect(func(_meta: Variant) -> void: label.mouse_default_cursor_shape = Control.CURSOR_IBEAM)
	return label
