@tool
extends VBoxContainer

## The Fight Lab's bottom panel: pick a [FightLabScenario], run it in a headless Godot process, chart the result.
## The matrix shows every character against every monster; the charts show the selected pairing over the sweep values.

const FightLabChart: GDScript = preload("uid://bq8r7sebmls8p")  # fight_lab_chart.gd
const RUNNER_SCENE: String = "res://addons/fight_lab/fight_lab_runner.tscn"
const RESULT_FILE: String = "user://fight_lab/result.json"
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

var _picker: EditorResourcePicker
var _run_button: Button
var _progress: ProgressBar
var _status: Label
var _matrix: GridContainer
var _charts: GridContainer
var _result: Dictionary = {}
var _pid: int = -1

func _init() -> void:
	name = "Fight Lab"
	custom_minimum_size = Vector2(0, 260)
	var bar: HBoxContainer = HBoxContainer.new()
	add_child(bar)
	_picker = EditorResourcePicker.new()
	_picker.base_type = "FightLabScenario"
	_picker.custom_minimum_size.x = 240
	bar.add_child(_picker)
	_run_button = Button.new()
	_run_button.text = "Run"
	_run_button.pressed.connect(_run)
	bar.add_child(_run_button)
	_progress = ProgressBar.new()
	_progress.custom_minimum_size.x = 160
	_progress.visible = false
	bar.add_child(_progress)
	_status = Label.new()
	bar.add_child(_status)
	var split: HSplitContainer = HSplitContainer.new()
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(split)
	var matrix_scroll: ScrollContainer = ScrollContainer.new()
	matrix_scroll.custom_minimum_size.x = 260
	split.add_child(matrix_scroll)
	_matrix = GridContainer.new()
	matrix_scroll.add_child(_matrix)
	var chart_scroll: ScrollContainer = ScrollContainer.new()
	chart_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	split.add_child(chart_scroll)
	_charts = GridContainer.new()
	_charts.columns = 3
	_charts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	chart_scroll.add_child(_charts)
	set_process(false)

func _ready() -> void:
	if FileAccess.file_exists(RESULT_FILE): _load_result("Last result")

func _run() -> void:
	var scenario: FightLabScenario = _picker.edited_resource as FightLabScenario
	if not scenario or not scenario.resource_path.begins_with("res://") or scenario.resource_path.contains("::"):
		_status.text = "Pick a scenario saved as its own .tres file."
		return
	# The run reads the scenario from disk
	ResourceSaver.save(scenario)
	var out: String = ProjectSettings.globalize_path(RESULT_FILE)
	DirAccess.make_dir_recursive_absolute(out.get_base_dir())
	for path: String in [out, out + ".progress"]:
		if FileAccess.file_exists(path): DirAccess.remove_absolute(path)
	var arguments: PackedStringArray = ["--headless", "--path", ProjectSettings.globalize_path("res://"), RUNNER_SCENE, "--", "--scenario=" + scenario.resource_path, "--out=" + out]
	_pid = OS.create_process(OS.get_executable_path(), arguments)
	if _pid < 0:
		_status.text = "Could not start Godot."
		return
	_run_button.disabled = true
	_progress.visible = true
	_progress.value = 0
	_status.text = "Simulating…"
	set_process(true)

func _process(_delta: float) -> void:
	var progress_path: String = ProjectSettings.globalize_path(RESULT_FILE) + ".progress"
	if FileAccess.file_exists(progress_path):
		var parts: PackedStringArray = FileAccess.get_file_as_string(progress_path).split("/")
		if parts.size() == 2 and parts[1].to_int() > 0: _progress.value = 100.0 * parts[0].to_int() / parts[1].to_int()
	if OS.is_process_running(_pid): return
	_pid = -1
	set_process(false)
	_run_button.disabled = false
	_progress.visible = false
	_load_result("Done")

func _load_result(status: String) -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(RESULT_FILE)) if FileAccess.file_exists(RESULT_FILE) else null
	if not parsed is Dictionary:
		_status.text = "The simulation failed; run the runner scene by hand to see why."
		return
	_result = parsed
	var cells: Array = _result["cells"]
	_status.text = "%s: %d cells × %d fights." % [status, cells.size(), int(cells[0]["stats"]["runs"]) if not cells.is_empty() else 0]
	var skipped: Array = _result.get("skipped", [])
	if not skipped.is_empty(): _status.text += " Skipped (attributes not rolled): %s." % ", ".join(skipped)
	_build_matrix()

## Characters down, monsters across; each cell tells the player's chance to win (its range over the sweep)
func _build_matrix() -> void:
	for child: Node in _matrix.get_children(): child.queue_free()
	var characters: Array[String] = _unique("character")
	var monsters: Array[String] = _unique("monster")
	_matrix.columns = monsters.size() + 1
	_matrix.add_child(Label.new())
	for monster: String in monsters: _matrix.add_child(_header(monster))
	var group: ButtonGroup = ButtonGroup.new()
	var first: Button = null
	for character: String in characters:
		_matrix.add_child(_header(character))
		for monster: String in monsters:
			var button: Button = Button.new()
			button.toggle_mode = true
			button.button_group = group
			button.text = _describe_pairing(_get_cells(character, monster))
			button.toggled.connect(func(on: bool) -> void:
				if on: _show_pairing(character, monster)
			)
			_matrix.add_child(button)
			if not first: first = button
	if first: first.button_pressed = true

func _describe_pairing(cells: Array[Dictionary]) -> String:
	var shares: Array[float] = []
	var exchanges: float = 0.0
	for cell: Dictionary in cells:
		shares.append(float(cell["stats"]["outcomes"]["won"]))
		exchanges += float(cell["stats"]["means"]["exchanges"]) / cells.size()
	if shares.size() == 1: return "won %d%%\n%.1f exchanges" % [roundi(shares[0] * 100.0), exchanges]
	return "won %d–%d%%\n%.1f exchanges" % [roundi(shares.min() * 100.0), roundi(shares.max() * 100.0), exchanges]

func _show_pairing(character: String, monster: String) -> void:
	for child: Node in _charts.get_children(): child.queue_free()
	var cells: Array[Dictionary] = _get_cells(character, monster)
	var swept: bool = not str(_result["sweep"]).is_empty()
	var categories: Array[String] = []
	for cell: Dictionary in cells: categories.append(str(int(cell["value"])) if swept else "%s vs %s" % [character, monster])
	var axis: String = " by %s" % _result["sweep"] if swept else ""
	_add_chart("Damage per exchange" + axis, categories, [_series(cells, "You deal", YOU, "per_exchange", "dealt"), _series(cells, "You take", FOE, "per_exchange", "taken")])
	_add_chart("Breath dice left" + axis, categories, [_series(cells, "You", YOU, "means", "breath_left"), _series(cells, "Foe", FOE, "means", "monster_breath_left")])
	var outcomes: Array[Dictionary] = []
	for outcome: String in OUTCOME_COLORS: outcomes.append(_series(cells, outcome, OUTCOME_COLORS[outcome], "outcomes", outcome))
	_add_chart("Outcome" + axis, categories, outcomes, true, true)
	if swept: _add_chart("Exchanges per fight" + axis, categories, [_series(cells, "Exchanges", YOU, "means", "exchanges")])
	else:
		_add_histogram("Exchanges per fight", cells[0], "exchanges")
		_add_histogram("Breath dice left at the end", cells[0], "breath_left")
	_add_chart("Marks per fight" + axis, categories, [_series(cells, "Weapon", WEAPON, "means", "weapon_marks"), _series(cells, "Shield", SHIELD, "means", "shield_marks"), _series(cells, "Armour", ARMOR, "means", "armor_marks")])
	_add_chart("Gear lost (share of fights)" + axis, categories, [
		_series(cells, "Weapon ruined", WEAPON, "rates", "weapon_ruined"),
		_series(cells, "Weapon dropped", WEAPON.darkened(0.4), "rates", "weapon_dropped"),
		_series(cells, "Shield ruined", SHIELD, "rates", "shield_ruined"),
		_series(cells, "Shield dropped", SHIELD.darkened(0.4), "rates", "shield_dropped"),
		_series(cells, "Armour ruined", ARMOR, "rates", "armor_ruined"),
	], false, true)

func _add_chart(title: String, categories: Array[String], series: Array[Dictionary], stacked: bool = false, percent: bool = false) -> void:
	var chart: Control = FightLabChart.new()
	chart.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_charts.add_child(chart)
	chart.show_data(title, categories, series, stacked, percent)

## Share of fights per value of [param key]
func _add_histogram(title: String, cell: Dictionary, key: String) -> void:
	var histogram: Dictionary = cell["stats"]["histograms"][key]
	var values: Array[int] = []
	for value: String in histogram: values.append(value.to_int())
	values.sort()
	var categories: Array[String] = []
	var shares: Array[float] = []
	if not values.is_empty():
		for value: int in range(values.min(), values.max() + 1):
			categories.append(str(value))
			shares.append(float(histogram.get(str(value), 0)) / float(cell["stats"]["runs"]))
	_add_chart(title, categories, [{"name": "Fights", "color": YOU, "values": shares}], false, true)

func _series(cells: Array[Dictionary], label: String, color: Color, group: String, key: String) -> Dictionary:
	var values: Array[float] = []
	for cell: Dictionary in cells: values.append(float(cell["stats"][group][key]))
	return {"name": label, "color": color, "values": values}

func _get_cells(character: String, monster: String) -> Array[Dictionary]:
	var cells: Array[Dictionary] = []
	for cell: Dictionary in _result["cells"]:
		if cell["character"] == character and cell["monster"] == monster: cells.append(cell)
	return cells

func _unique(key: String) -> Array[String]:
	var names: Array[String] = []
	for cell: Dictionary in _result["cells"]:
		if not names.has(str(cell[key])): names.append(str(cell[key]))
	return names

static func _header(text: String) -> Label:
	var label: Label = Label.new()
	label.text = text
	return label
