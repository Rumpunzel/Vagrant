@tool
extends HSplitContainer

## The result of many fights: the matrix on the left, the charts of what is selected in it on the right.
## Row header: one character against every monster. Column header: every character against one monster.
## Cell: one pairing in detail (its distributions, or the sweep values). Ctrl+click cells: those pairings side by side.

const FightLabChart: GDScript = preload("uid://bq8r7sebmls8p")  # fight_lab_chart.gd
const SECTIONS: Dictionary[String, String] = {
	"outcome": "Outcome",
	"cost": "Cost of a win",
	"damage": "Damage & breath",
	"length": "Fight length",
	"gear": "Gear wear",
}
const OUTCOME_COLORS: Dictionary[String, Color] = {
	"won": Color("4caf50"),
	"lost": Color("e53935"),
	"draw": Color("9e9e9e"),
	"fled": Color("42a5f5"),
	"unfinished": Color("616161"),
}
const YOU: Color = Color("42a5f5")
const FOE: Color = Color("e53935")
const WEAPON: Color = Color("ffb74d")
const SHIELD: Color = Color("9575cd")
const ARMOR: Color = Color("4db6ac")

var shown_sections: Array[String] = []

var _result: Dictionary = {}
var _matrix: GridContainer
var _heading: Label
var _sweep_value: OptionButton
var _sections: VBoxContainer
## Selected cells as (character, monster); with a row or column chosen instead, the cells of it
var _selection: Array[Vector2i] = []
## "row", "column" or "cells"
var _view: String = ""
var _view_index: int = -1

func _init() -> void:
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	var matrix_scroll: ScrollContainer = ScrollContainer.new()
	matrix_scroll.custom_minimum_size.x = 280
	add_child(matrix_scroll)
	_matrix = GridContainer.new()
	matrix_scroll.add_child(_matrix)
	var right: VBoxContainer = VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(right)
	var header: HBoxContainer = HBoxContainer.new()
	right.add_child(header)
	_heading = Label.new()
	_heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(_heading)
	_sweep_value = OptionButton.new()
	_sweep_value.tooltip_text = "Sweep value the comparison shows"
	_sweep_value.item_selected.connect(func(_index: int) -> void: _refresh())
	header.add_child(_sweep_value)
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	right.add_child(scroll)
	_sections = VBoxContainer.new()
	_sections.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_sections)

func show_result(result: Dictionary) -> void:
	_result = result
	_sweep_value.clear()
	for value: Variant in _result.get("sweep_values", []): _sweep_value.add_item("%s = %d" % [_result["sweep"], int(value)])
	_sweep_value.visible = false
	_selection.clear()
	_view = ""
	_build_matrix()
	if not _get_characters().is_empty(): _select_row(0)

func set_sections(sections: Array[String]) -> void:
	shown_sections = sections
	_refresh()

func _build_matrix() -> void:
	for child: Node in _matrix.get_children(): child.queue_free()
	var characters: Array[String] = _get_characters()
	var monsters: Array[String] = _get_monsters()
	_matrix.columns = monsters.size() + 1
	_matrix.add_child(Label.new())
	for monster: int in monsters.size(): _matrix.add_child(_header_button(monsters[monster], "Every character against the %s" % monsters[monster], _select_column.bind(monster)))
	for character: int in characters.size():
		_matrix.add_child(_header_button(characters[character], "%s against every monster" % characters[character], _select_row.bind(character)))
		for monster: int in monsters.size():
			var button: Button = Button.new()
			button.set_meta("cell", Vector2i(character, monster))
			button.tooltip_text = "Click: this pairing in detail. Ctrl+click: add it to a side-by-side comparison."
			button.pressed.connect(_on_cell_pressed.bind(Vector2i(character, monster)))
			_matrix.add_child(button)
	_update_matrix()

## Each cell coloured by the chance to win, red to green; its range over the sweep if there is one
func _update_matrix() -> void:
	for child: Node in _matrix.get_children():
		if not child.has_meta("cell"): continue
		var button: Button = child
		var cell: Vector2i = button.get_meta("cell")
		var cells: Array[Dictionary] = _get_cells(cell.x, cell.y)
		if cells.is_empty():
			button.text = "—"
			continue
		var shares: Array[float] = []
		var exchanges: float = 0.0
		for entry: Dictionary in cells:
			shares.append(float(entry["stats"]["outcomes"]["won"]))
			exchanges += float(entry["stats"]["means"]["exchanges"]) / cells.size()
		var won: String = "%d%%" % roundi(shares[0] * 100.0) if shares.size() == 1 else "%d–%d%%" % [roundi(shares.min() * 100.0), roundi(shares.max() * 100.0)]
		button.text = "won %s\n%.1f exchanges" % [won, exchanges]
		var style: StyleBoxFlat = StyleBoxFlat.new()
		var average: float = 0.0
		for share: float in shares: average += share / shares.size()
		style.bg_color = Color("8e2b2b").lerp(Color("2e7d32"), average)
		style.set_content_margin_all(6)
		style.set_corner_radius_all(3)
		if _selection.has(cell):
			style.set_border_width_all(2)
			style.border_color = Color.WHITE
		for state: String in ["normal", "hover", "pressed", "focus"]: button.add_theme_stylebox_override(state, style)

func _select_row(character: int) -> void:
	_view = "row"
	_view_index = character
	_selection.clear()
	for monster: int in _get_monsters().size(): _selection.append(Vector2i(character, monster))
	_refresh()

func _select_column(monster: int) -> void:
	_view = "column"
	_view_index = monster
	_selection.clear()
	for character: int in _get_characters().size(): _selection.append(Vector2i(character, monster))
	_refresh()

func _on_cell_pressed(cell: Vector2i) -> void:
	if Input.is_key_pressed(KEY_CTRL) and _view == "cells":
		if _selection.has(cell):
			if _selection.size() > 1: _selection.erase(cell)
		else: _selection.append(cell)
	else:
		_selection = [cell] as Array[Vector2i]
	_view = "cells"
	_refresh()

func _refresh() -> void:
	if _result.is_empty() or _view.is_empty(): return
	_update_matrix()
	for child: Node in _sections.get_children(): child.queue_free()
	var swept: bool = not str(_result.get("sweep", "")).is_empty()
	var detail: bool = _view == "cells" and _selection.size() == 1
	_sweep_value.visible = swept and not detail
	var characters: Array[String] = _get_characters()
	var monsters: Array[String] = _get_monsters()
	var categories: Array[String] = []
	var stats: Array[Dictionary] = []
	if detail and swept:
		var cell: Vector2i = _selection[0]
		_heading.text = "%s vs %s by %s" % [characters[cell.x], monsters[cell.y], _result["sweep"]]
		for entry: Dictionary in _get_cells(cell.x, cell.y):
			categories.append(str(int(entry["value"])))
			stats.append(entry["stats"])
	elif detail:
		var cell: Vector2i = _selection[0]
		_heading.text = "%s vs %s" % [characters[cell.x], monsters[cell.y]]
		_show_distributions(_get_cells(cell.x, cell.y)[0]["stats"])
		return
	else:
		match _view:
			"row": _heading.text = "%s against every monster" % characters[_view_index]
			"column": _heading.text = "Every character against the %s" % monsters[_view_index]
			_: _heading.text = "Side by side"
		for cell: Vector2i in _selection:
			var entry: Dictionary = _get_cell(cell.x, cell.y)
			if entry.is_empty(): continue
			match _view:
				"row": categories.append(monsters[cell.y])
				"column": categories.append(characters[cell.x])
				_: categories.append("%s vs %s" % [characters[cell.x], monsters[cell.y]])
			stats.append(entry["stats"])
	_show_comparison(categories, stats)

## One bar (group) per category, from the matching [param stats]
func _show_comparison(categories: Array[String], stats: Array[Dictionary]) -> void:
	if _shows("outcome"):
		var outcomes: Array[Dictionary] = []
		for outcome: String in OUTCOME_COLORS: outcomes.append(_series(stats, outcome, OUTCOME_COLORS[outcome], ["outcomes", outcome]))
		_add_section("outcome", [_chart("Outcome (share of fights)", categories, outcomes, true, true)])
	if _shows("cost"): _add_section("cost", [
		_chart("Injury taken in won fights", categories, [_series(stats, "Injury", FOE, ["won", "means", "taken"])]),
		_chart("Breath dice spent in won fights", categories, [_series(stats, "Breath dice", YOU, ["won", "means", "breath_spent"])]),
		_chart("Fights won", categories, [_series(stats, "Won", OUTCOME_COLORS["won"], ["outcomes", "won"])], false, true),
	])
	if _shows("damage"): _add_section("damage", [
		_chart("Damage per fight", categories, [_series(stats, "You deal", YOU, ["means", "dealt"]), _series(stats, "You take", FOE, ["means", "taken"])]),
		_chart("Breath dice per fight", categories, [
			_series(stats, "You spend", YOU, ["means", "breath_spent"]),
			_series(stats, "You keep", YOU.darkened(0.4), ["means", "breath_left"]),
			_series(stats, "Foe keeps", FOE, ["means", "monster_breath_left"]),
		]),
	])
	if _shows("length"): _add_section("length", [_chart("Exchanges per fight", categories, [_series(stats, "Exchanges", YOU, ["means", "exchanges"])])])
	if _shows("gear"): _add_gear_section(categories, stats)

## The spread of one pairing's fights: how often each value came up
func _show_distributions(stats: Dictionary) -> void:
	var all: Array[String] = ["All fights"]
	if _shows("outcome"):
		var outcomes: Array[Dictionary] = []
		for outcome: String in OUTCOME_COLORS: outcomes.append(_series([stats], outcome, OUTCOME_COLORS[outcome], ["outcomes", outcome]))
		_add_section("outcome", [_chart("Outcome (share of fights)", all, outcomes, true, true)])
	if _shows("cost"):
		var won: Dictionary = stats["won"]
		if int(won["runs"]) == 0: _add_section("cost", [_note("No fight was won.")])
		else: _add_section("cost", [
			_histogram("Injury taken in won fights", won, "taken", FOE),
			_histogram("Breath dice spent in won fights", won, "breath_spent", YOU),
		])
	if _shows("damage"): _add_section("damage", [
		_histogram("Damage dealt per fight", stats, "dealt", YOU),
		_histogram("Damage taken per fight", stats, "taken", FOE),
		_histogram("Breath dice left at the end", stats, "breath_left", YOU),
	])
	if _shows("length"): _add_section("length", [_histogram("Exchanges per fight", stats, "exchanges", YOU)])
	if _shows("gear"): _add_gear_section(all, [stats] as Array[Dictionary])

func _add_gear_section(categories: Array[String], stats: Array[Dictionary]) -> void:
	var marks: Array[Dictionary] = [
		_series(stats, "Weapon", WEAPON, ["means", "weapon_marks"]),
		_series(stats, "Shield", SHIELD, ["means", "shield_marks"]),
		_series(stats, "Armour", ARMOR, ["means", "armor_marks"]),
	]
	var lost: Array[Dictionary] = [
		_series(stats, "Weapon ruined", WEAPON, ["rates", "weapon_ruined"]),
		_series(stats, "Weapon dropped", WEAPON.darkened(0.4), ["rates", "weapon_dropped"]),
		_series(stats, "Shield ruined", SHIELD, ["rates", "shield_ruined"]),
		_series(stats, "Shield dropped", SHIELD.darkened(0.4), ["rates", "shield_dropped"]),
		_series(stats, "Armour ruined", ARMOR, ["rates", "armor_ruined"]),
	]
	if (marks + lost).all(func(entry: Dictionary) -> bool: return entry["values"].all(func(value: float) -> bool: return value == 0.0)):
		_add_section("gear", [_note("No gear was marked, ruined or dropped.")])
		return
	_add_section("gear", [_chart("Marks per fight", categories, marks), _chart("Gear lost (share of fights)", categories, lost, false, true)])

func _add_section(key: String, contents: Array[Control]) -> void:
	var title: Label = Label.new()
	title.text = SECTIONS[key]
	title.add_theme_font_size_override("font_size", get_theme_default_font_size() + 3)
	_sections.add_child(title)
	var flow: HFlowContainer = HFlowContainer.new()
	flow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_sections.add_child(flow)
	for content: Control in contents: flow.add_child(content)
	_sections.add_child(HSeparator.new())

func _chart(title: String, categories: Array[String], series: Array[Dictionary], stacked: bool = false, percent: bool = false) -> Control:
	var chart: Control = FightLabChart.new()
	chart.show_data(title, categories, series, stacked, percent)
	return chart

## Share of fights per value of [param key] in [param stats]' histograms
func _histogram(title: String, stats: Dictionary, key: String, color: Color) -> Control:
	var histogram: Dictionary = stats["histograms"][key]
	var values: Array[int] = []
	for value: String in histogram: values.append(value.to_int())
	var categories: Array[String] = []
	var shares: Array[float] = []
	if not values.is_empty():
		for value: int in range(values.min(), values.max() + 1):
			categories.append(str(value))
			shares.append(float(histogram.get(str(value), 0)) / float(stats["runs"]))
	return _chart(title, categories, [{"name": "Fights", "color": color, "values": shares}], false, true)

static func _note(text: String) -> Control:
	var label: Label = Label.new()
	label.text = text
	label.modulate.a = 0.7
	return label

## [param path] leads through each stats dictionary to the value
static func _series(stats: Array[Dictionary], label: String, color: Color, path: Array[String]) -> Dictionary:
	var values: Array[float] = []
	for entry: Dictionary in stats:
		var value: Variant = entry
		for key: String in path: value = value[key]
		values.append(float(value))
	return {"name": label, "color": color, "values": values}

func _shows(section: String) -> bool: return shown_sections.has(section)

func _get_characters() -> Array[String]:
	var names: Array[String] = []
	names.assign(_result.get("characters", []))
	return names

func _get_monsters() -> Array[String]:
	var names: Array[String] = []
	names.assign(_result.get("monsters", []))
	return names

## Every cell of the pairing, one per sweep value
func _get_cells(character: int, monster: int) -> Array[Dictionary]:
	var cells: Array[Dictionary] = []
	for cell: Dictionary in _result.get("cells", []):
		if int(cell["character"]) == character and int(cell["monster"]) == monster: cells.append(cell)
	return cells

## The pairing's cell at the chosen sweep value; empty for skipped characters
func _get_cell(character: int, monster: int) -> Dictionary:
	var cells: Array[Dictionary] = _get_cells(character, monster)
	if cells.is_empty(): return {}
	return cells[clampi(_sweep_value.selected, 0, cells.size() - 1)]

static func _header_button(text: String, tooltip: String, on_pressed: Callable) -> Button:
	var button: Button = Button.new()
	button.text = text
	button.flat = true
	button.tooltip_text = tooltip
	button.pressed.connect(on_pressed)
	return button
