@tool
extends VBoxContainer

## The Fight Lab's bottom panel: pick a [FightLabScenario] and how to run it, run it in a headless Godot process, show the result.
## The run settings are kept in [constant SETTINGS_FILE] for the child process and for next time.

const FightLabResults: GDScript = preload("uid://cuh3q2c6v1lmb")  # fight_lab_results.gd
const FightLabFightView: GDScript = preload("uid://cnyxw8v3kh2qa")  # fight_lab_fight_view.gd
## Handed to the child process on its command line, which takes no uid://
const RUNNER_SCENE: String = "res://addons/fight_lab/fight_lab_runner.tscn"
const SETTINGS_FILE: String = "user://fight_lab/settings.tres"
const RESULT_FILE: String = "user://fight_lab/result.json"

var _settings: FightLabRunSettings
var _scenario_picker: EditorResourcePicker
var _mode: OptionButton
var _fights: EditorSpinSlider
var _sweep_picker: EditorResourcePicker
var _character: OptionButton
var _monster: OptionButton
var _max_exchanges: EditorSpinSlider
var _seed: SpinBox
var _run_button: Button
var _progress: ProgressBar
var _status: Label
var _section_bar: HBoxContainer
var _results: Control
var _fight_view: Control
var _pid: int = -1

func _init() -> void:
	name = "Fight Lab"
	custom_minimum_size = Vector2(0, 300)
	_settings = _load_settings()
	var bar: HBoxContainer = HBoxContainer.new()
	add_child(bar)
	_scenario_picker = _picker("FightLabScenario", "Scenario: who fights whom", bar)
	_scenario_picker.edited_resource = _settings.scenario
	_scenario_picker.resource_changed.connect(func(_resource: Resource) -> void: _update_pairing_options())
	_mode = OptionButton.new()
	_mode.add_item("Many fights", FightLabRunSettings.Mode.MANY_FIGHTS)
	_mode.add_item("One fight", FightLabRunSettings.Mode.ONE_FIGHT)
	_mode.selected = _settings.mode
	_mode.item_selected.connect(func(_index: int) -> void: _update_mode())
	bar.add_child(_mode)
	_fights = _spin_slider("Fights", 1, 10000, _settings.fights, bar)
	_sweep_picker = _picker("FightLabSweep", "Optional sweep: every matchup once per value", bar)
	_sweep_picker.edited_resource = _settings.sweep
	_character = OptionButton.new()
	bar.add_child(_character)
	_monster = OptionButton.new()
	bar.add_child(_monster)
	_max_exchanges = _spin_slider("Max exchanges", 1, 200, _settings.max_exchanges, bar)
	_seed = SpinBox.new()
	_seed.prefix = "Seed"
	_seed.max_value = 999999
	_seed.value = _settings.random_seed
	_seed.tooltip_text = "0: a different seed every run"
	bar.add_child(_seed)
	_run_button = Button.new()
	_run_button.text = "Run"
	_run_button.pressed.connect(_run)
	bar.add_child(_run_button)
	_progress = ProgressBar.new()
	_progress.custom_minimum_size.x = 120
	_progress.visible = false
	bar.add_child(_progress)
	_status = Label.new()
	_status.clip_text = true
	_status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.add_child(_status)
	_section_bar = HBoxContainer.new()
	add_child(_section_bar)
	var shown: Array = _settings.sections if not _settings.sections.is_empty() else FightLabResults.SECTIONS.keys()
	for key: String in FightLabResults.SECTIONS:
		var check: CheckBox = CheckBox.new()
		check.text = FightLabResults.SECTIONS[key]
		check.button_pressed = shown.has(key)
		check.toggled.connect(func(_on: bool) -> void: _update_sections())
		check.set_meta("section", key)
		_section_bar.add_child(check)
	_results = FightLabResults.new()
	add_child(_results)
	_fight_view = FightLabFightView.new()
	_fight_view.visible = false
	add_child(_fight_view)
	_update_pairing_options()
	_update_mode()
	_update_sections()
	set_process(false)

func _ready() -> void:
	if FileAccess.file_exists(RESULT_FILE): _load_result("Last result")

func _run() -> void:
	var scenario: FightLabScenario = _scenario_picker.edited_resource as FightLabScenario
	if not scenario or not scenario.resource_path.begins_with("res://") or scenario.resource_path.contains("::"):
		_status.text = "Pick a scenario saved as its own .tres file."
		return
	# The child process reads both from disk
	ResourceSaver.save(scenario)
	_store_settings()
	for path: String in [RESULT_FILE, RESULT_FILE + ".progress"]:
		if FileAccess.file_exists(path): DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	var arguments: PackedStringArray = ["--headless", "--path", ProjectSettings.globalize_path("res://"), RUNNER_SCENE, "--", "--settings=" + SETTINGS_FILE, "--out=" + RESULT_FILE]
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
	if FileAccess.file_exists(RESULT_FILE + ".progress"):
		var parts: PackedStringArray = FileAccess.get_file_as_string(RESULT_FILE + ".progress").split("/")
		if parts.size() == 2 and parts[1].to_int() > 0: _progress.value = 100.0 * parts[0].to_int() / parts[1].to_int()
	if OS.is_process_running(_pid): return
	_pid = -1
	set_process(false)
	_run_button.disabled = false
	_progress.visible = false
	_load_result("Done")

func _load_result(status: String) -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(RESULT_FILE)) if FileAccess.file_exists(RESULT_FILE) else null
	if not parsed is Dictionary or not (parsed as Dictionary).has("characters"):
		_status.text = "The simulation failed; run the runner scene by hand to see why." if status == "Done" else ""
		return
	var result: Dictionary = parsed
	var one_fight: bool = result.has("fight")
	_results.visible = not one_fight
	_section_bar.visible = not one_fight
	_fight_view.visible = one_fight
	if one_fight:
		_fight_view.show_result(result)
		_status.text = "%s: one fight." % status
		return
	_results.show_result(result)
	var cells: Array = result["cells"]
	_status.text = "%s: %d cells × %d fights." % [status, cells.size(), int(cells[0]["stats"]["runs"]) if not cells.is_empty() else 0]
	var skipped: Array = result.get("skipped", [])
	if not skipped.is_empty(): _status.text += " Skipped (attributes not rolled): %s." % ", ".join(skipped)

func _update_mode() -> void:
	var one_fight: bool = _mode.get_selected_id() == FightLabRunSettings.Mode.ONE_FIGHT
	_fights.visible = not one_fight
	_sweep_picker.visible = not one_fight
	_character.visible = one_fight
	_monster.visible = one_fight
	_run_button.text = "Fight" if one_fight else "Run"

## The scenario's characters and monsters to pick the one fight from
func _update_pairing_options() -> void:
	var scenario: FightLabScenario = _scenario_picker.edited_resource as FightLabScenario
	for option: OptionButton in [_character, _monster]: option.clear()
	if not scenario: return
	for profile: CharacterProfile in scenario.characters: _character.add_item(profile.name if profile else "(empty)")
	for profile: MonsterProfile in scenario.monsters: _monster.add_item(profile.name if profile else "(empty)")
	_character.selected = clampi(_settings.character, 0, _character.item_count - 1)
	_monster.selected = clampi(_settings.monster, 0, _monster.item_count - 1)

func _update_sections() -> void:
	_settings.sections = _get_sections()
	_results.set_sections(_get_sections())

func _get_sections() -> Array[String]:
	var sections: Array[String] = []
	for check: Node in _section_bar.get_children():
		if (check as CheckBox).button_pressed: sections.append(check.get_meta("section"))
	return sections

func _store_settings() -> void:
	_settings.scenario = _scenario_picker.edited_resource as FightLabScenario
	_settings.mode = _mode.get_selected_id() as FightLabRunSettings.Mode
	_settings.fights = int(_fights.value)
	_settings.max_exchanges = int(_max_exchanges.value)
	_settings.random_seed = int(_seed.value)
	_settings.sweep = _sweep_picker.edited_resource as FightLabSweep
	_settings.character = maxi(_character.selected, 0)
	_settings.monster = maxi(_monster.selected, 0)
	_settings.sections = _get_sections()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SETTINGS_FILE).get_base_dir())
	ResourceSaver.save(_settings, SETTINGS_FILE)

static func _load_settings() -> FightLabRunSettings:
	var settings: FightLabRunSettings = null
	if FileAccess.file_exists(SETTINGS_FILE): settings = ResourceLoader.load(SETTINGS_FILE, "", ResourceLoader.CACHE_MODE_IGNORE) as FightLabRunSettings
	return settings if settings else FightLabRunSettings.new()

static func _picker(base_type: String, tooltip: String, parent: Control) -> EditorResourcePicker:
	var picker: EditorResourcePicker = EditorResourcePicker.new()
	picker.base_type = base_type
	picker.tooltip_text = tooltip
	picker.custom_minimum_size.x = 200
	parent.add_child(picker)
	return picker

static func _spin_slider(label: String, min_value: int, max_value: int, value: int, parent: Control) -> EditorSpinSlider:
	var slider: EditorSpinSlider = EditorSpinSlider.new()
	slider.label = label
	slider.min_value = min_value
	slider.max_value = max_value
	slider.step = 1
	slider.value = value
	slider.custom_minimum_size.x = 150
	parent.add_child(slider)
	return slider
